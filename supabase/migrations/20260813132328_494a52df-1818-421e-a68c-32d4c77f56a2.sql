
-- ORG ROLE ENUM
CREATE TYPE public.app_role AS ENUM ('owner', 'member');

-- ORGANIZATIONS
CREATE TABLE public.organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  owner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, UPDATE ON public.organizations TO authenticated;
GRANT ALL ON public.organizations TO service_role;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- ORGANIZATION MEMBERS (roles live here, never on profiles)
CREATE TABLE public.organization_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role public.app_role NOT NULL DEFAULT 'member',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id)
);
CREATE INDEX organization_members_org_idx ON public.organization_members(organization_id);
GRANT SELECT ON public.organization_members TO authenticated;
GRANT ALL ON public.organization_members TO service_role;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- HELPERS (security definer to avoid recursive RLS)
CREATE OR REPLACE FUNCTION public.current_org_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT organization_id FROM public.organization_members WHERE user_id = auth.uid() LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.has_org_role(_role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid() AND role = _role
  );
$$;

REVOKE EXECUTE ON FUNCTION public.current_org_id() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.has_org_role(public.app_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_org_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.has_org_role(public.app_role) TO authenticated;

CREATE POLICY "Members read their organization" ON public.organizations
  FOR SELECT TO authenticated USING (id = public.current_org_id());
CREATE POLICY "Owners update their organization" ON public.organizations
  FOR UPDATE TO authenticated USING (id = public.current_org_id() AND public.has_org_role('owner'))
  WITH CHECK (id = public.current_org_id());

CREATE POLICY "Members read same-org memberships" ON public.organization_members
  FOR SELECT TO authenticated USING (organization_id = public.current_org_id());

-- PROFILES: restrict reads to the same organization
DROP POLICY IF EXISTS "Profiles readable" ON public.profiles;
CREATE POLICY "Profiles readable in same org" ON public.profiles
  FOR SELECT TO authenticated USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.organization_members m
      WHERE m.user_id = profiles.id AND m.organization_id = public.current_org_id()
    )
  );

-- PERMITS: tenant scoping
ALTER TABLE public.permits ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
CREATE INDEX permits_org_idx ON public.permits(organization_id);
ALTER TABLE public.permits DROP CONSTRAINT IF EXISTS permits_file_number_key;
CREATE UNIQUE INDEX permits_org_file_number_key ON public.permits(organization_id, file_number);

ALTER TABLE public.renewals ADD COLUMN organization_id uuid REFERENCES public.organizations(id) ON DELETE CASCADE;
CREATE INDEX renewals_org_idx ON public.renewals(organization_id);

CREATE OR REPLACE FUNCTION public.tg_set_org_id() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NEW.organization_id IS NULL THEN
    NEW.organization_id := public.current_org_id();
  END IF;
  IF NEW.organization_id IS NULL THEN
    RAISE EXCEPTION 'No organization for current user';
  END IF;
  RETURN NEW;
END; $$;
REVOKE EXECUTE ON FUNCTION public.tg_set_org_id() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER permits_set_org BEFORE INSERT ON public.permits
  FOR EACH ROW EXECUTE FUNCTION public.tg_set_org_id();
CREATE TRIGGER renewals_set_org BEFORE INSERT ON public.renewals
  FOR EACH ROW EXECUTE FUNCTION public.tg_set_org_id();

DROP POLICY IF EXISTS "Permits readable" ON public.permits;
DROP POLICY IF EXISTS "Permits insert" ON public.permits;
DROP POLICY IF EXISTS "Permits update" ON public.permits;
DROP POLICY IF EXISTS "Permits delete" ON public.permits;
CREATE POLICY "Org members read permits" ON public.permits
  FOR SELECT TO authenticated USING (organization_id = public.current_org_id());
CREATE POLICY "Org members insert permits" ON public.permits
  FOR INSERT TO authenticated WITH CHECK (organization_id IS NULL OR organization_id = public.current_org_id());
CREATE POLICY "Org members update permits" ON public.permits
  FOR UPDATE TO authenticated USING (organization_id = public.current_org_id())
  WITH CHECK (organization_id = public.current_org_id());
CREATE POLICY "Org owners delete permits" ON public.permits
  FOR DELETE TO authenticated USING (organization_id = public.current_org_id() AND public.has_org_role('owner'));

DROP POLICY IF EXISTS "Renewals readable" ON public.renewals;
DROP POLICY IF EXISTS "Renewals insert" ON public.renewals;
CREATE POLICY "Org members read renewals" ON public.renewals
  FOR SELECT TO authenticated USING (organization_id = public.current_org_id());
CREATE POLICY "Org members insert renewals" ON public.renewals
  FOR INSERT TO authenticated WITH CHECK (organization_id IS NULL OR organization_id = public.current_org_id());

-- SIGNUP: owner gets a brand new organization, invited users join the inviter's org
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_org_id uuid;
  v_name text;
BEGIN
  v_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email,'@',1));

  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (NEW.id, v_name, NEW.email, 'administrator')
  ON CONFLICT (id) DO NOTHING;

  v_org_id := NULLIF(NEW.raw_user_meta_data->>'organization_id','')::uuid;

  IF v_org_id IS NULL THEN
    INSERT INTO public.organizations (name, owner_id)
    VALUES (COALESCE(NULLIF(NEW.raw_user_meta_data->>'organization_name',''), v_name || '''s Organization'), NEW.id)
    RETURNING id INTO v_org_id;

    INSERT INTO public.organization_members (organization_id, user_id, role)
    VALUES (v_org_id, NEW.id, 'owner') ON CONFLICT (user_id) DO NOTHING;
  ELSE
    INSERT INTO public.organization_members (organization_id, user_id, role)
    VALUES (v_org_id, NEW.id, 'member') ON CONFLICT (user_id) DO NOTHING;
  END IF;

  RETURN NEW;
END; $$;
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER organizations_set_updated_at BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();
