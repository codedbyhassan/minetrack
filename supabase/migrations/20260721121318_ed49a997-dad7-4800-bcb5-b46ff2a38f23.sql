
-- SECTORS
CREATE TABLE public.sectors (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  icon text NOT NULL DEFAULT '',
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.sectors TO authenticated;
GRANT ALL ON public.sectors TO service_role;
ALTER TABLE public.sectors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Sectors readable" ON public.sectors FOR SELECT TO authenticated USING (true);

-- UNDERTAKING TYPES
CREATE TABLE public.undertaking_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sector_id uuid NOT NULL REFERENCES public.sectors(id) ON DELETE CASCADE,
  name text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sector_id, name)
);
GRANT SELECT ON public.undertaking_types TO authenticated;
GRANT ALL ON public.undertaking_types TO service_role;
ALTER TABLE public.undertaking_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Undertaking types readable" ON public.undertaking_types FOR SELECT TO authenticated USING (true);

-- PROFILES
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  email text,
  role text NOT NULL DEFAULT 'administrator',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles readable" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Users insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);

-- PERMITS
CREATE TABLE public.permits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  file_number text NOT NULL UNIQUE,
  proponent_name text NOT NULL,
  contact_person text,
  contact_phone text,
  region text NOT NULL,
  district text,
  town_site text,
  sector_id uuid NOT NULL REFERENCES public.sectors(id),
  undertaking_type_id uuid NOT NULL REFERENCES public.undertaking_types(id),
  capacity numeric,
  capacity_unit text,
  effective_date date,
  validity_months int,
  expiry_date date,
  permit_fee numeric NOT NULL DEFAULT 0,
  processing_fee numeric NOT NULL DEFAULT 0,
  total_cost numeric GENERATED ALWAYS AS (COALESCE(permit_fee,0) + COALESCE(processing_fee,0)) STORED,
  latitude numeric,
  longitude numeric,
  revoked boolean NOT NULL DEFAULT false,
  created_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.permits TO authenticated;
GRANT ALL ON public.permits TO service_role;
ALTER TABLE public.permits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Permits readable" ON public.permits FOR SELECT TO authenticated USING (true);
CREATE POLICY "Permits insert" ON public.permits FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Permits update" ON public.permits FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Permits delete" ON public.permits FOR DELETE TO authenticated USING (true);
CREATE INDEX permits_sector_idx ON public.permits(sector_id);
CREATE INDEX permits_undertaking_idx ON public.permits(undertaking_type_id);
CREATE INDEX permits_region_idx ON public.permits(region);
CREATE INDEX permits_expiry_idx ON public.permits(expiry_date);

-- expiry_date computed via trigger (interval math isn't immutable for generated cols)
CREATE OR REPLACE FUNCTION public.tg_compute_expiry() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.effective_date IS NOT NULL AND NEW.validity_months IS NOT NULL THEN
    NEW.expiry_date := (NEW.effective_date + (NEW.validity_months || ' months')::interval)::date;
  ELSE
    NEW.expiry_date := NULL;
  END IF;
  RETURN NEW;
END; $$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER permits_compute_expiry BEFORE INSERT OR UPDATE OF effective_date, validity_months ON public.permits
  FOR EACH ROW EXECUTE FUNCTION public.tg_compute_expiry();

-- RENEWALS
CREATE TABLE public.renewals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  permit_id uuid NOT NULL REFERENCES public.permits(id) ON DELETE CASCADE,
  previous_expiry_date date,
  new_effective_date date NOT NULL,
  new_validity_months int NOT NULL,
  new_expiry_date date NOT NULL,
  renewal_fee numeric NOT NULL DEFAULT 0,
  processing_fee numeric NOT NULL DEFAULT 0,
  total_cost numeric GENERATED ALWAYS AS (COALESCE(renewal_fee,0) + COALESCE(processing_fee,0)) STORED,
  renewed_by uuid REFERENCES auth.users(id),
  renewed_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.renewals TO authenticated;
GRANT ALL ON public.renewals TO service_role;
ALTER TABLE public.renewals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Renewals readable" ON public.renewals FOR SELECT TO authenticated USING (true);
CREATE POLICY "Renewals insert" ON public.renewals FOR INSERT TO authenticated WITH CHECK (true);
CREATE INDEX renewals_permit_idx ON public.renewals(permit_id);

-- updated_at triggers
CREATE OR REPLACE FUNCTION public.tg_set_updated_at() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER permits_set_updated_at BEFORE UPDATE ON public.permits FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();
CREATE TRIGGER profiles_set_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email,'@',1)),
    NEW.email,
    'administrator'
  ) ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END; $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- SEED sectors + undertaking types
WITH s AS (
  INSERT INTO public.sectors (name, icon, sort_order) VALUES
    ('Mining','⛏️',1),
    ('Tourism','🌴',2),
    ('Infrastructure','🏗️',3),
    ('Manufacturing','🏭',4),
    ('Health','🏥',5),
    ('Energy','⚡',6),
    ('Agrochemical','🧪',7),
    ('Agriculture','🌾',8)
  RETURNING id, name
)
INSERT INTO public.undertaking_types (sector_id, name, sort_order)
SELECT s.id, u.name, u.ord FROM s JOIN (VALUES
  ('Mining','Gold',1),('Mining','Diamond',2),('Mining','Bauxite',3),('Mining','Manganese',4),('Mining','Iron Ore',5),('Mining','Limestone',6),('Mining','Sand & Gravel',7),('Mining','Other Minerals',8),
  ('Tourism','Hotels',1),('Tourism','Resorts',2),('Tourism','Parks',3),('Tourism','Tours',4),('Tourism','Cultural Sites',5),
  ('Infrastructure','Roads',1),('Infrastructure','Bridges',2),('Infrastructure','Buildings',3),('Infrastructure','Water Systems',4),('Infrastructure','Telecommunications',5),
  ('Manufacturing','Food Processing',1),('Manufacturing','Textiles',2),('Manufacturing','Chemicals',3),('Manufacturing','Electronics',4),('Manufacturing','Machinery',5),
  ('Health','Hospitals',1),('Health','Clinics',2),('Health','Pharmacies',3),('Health','Laboratories',4),('Health','Medical Equipment',5),
  ('Energy','Solar',1),('Energy','Wind',2),('Energy','Hydro',3),('Energy','Oil & Gas',4),('Energy','Thermal',5),('Energy','Nuclear',6),
  ('Agrochemical','Fertilizers',1),('Agrochemical','Pesticides',2),('Agrochemical','Herbicides',3),('Agrochemical','Soil Conditioners',4),
  ('Agriculture','Crop Farming',1),('Agriculture','Livestock',2),('Agriculture','Fisheries',3),('Agriculture','Forestry',4),('Agriculture','Agro-processing',5)
) AS u(sector, name, ord) ON s.name = u.sector;
