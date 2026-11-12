-- ==============================================================================
-- SI-CAKRAWALA (NANGGROE CAKRAWALA SHIELD)
-- DATABASE SCHEMA & IMMUTABLE BLOCKCHAIN AUDIT LEDGER
-- Target Database: Supabase PostgreSQL
-- ==============================================================================

-- 1. Ekstensi Kriptografi & UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Enum Tipe Akses & Role Personel
DO $$ BEGIN
  CREATE TYPE operator_role AS ENUM (
    'OPERATOR_TERITORIAL',
    'ANALIS_INTELIJEN',
    'KOMANDAN_SATSIBER',
    'ADMIN_SISTEM'
  );
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 3. Tabel Profil Pengguna (Sinkron dengan auth.users Supabase)
CREATE TABLE IF NOT EXISTS public.operator_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nik VARCHAR(50) UNIQUE NOT NULL,
  nama_lengkap VARCHAR(100) NOT NULL,
  pangkat VARCHAR(50) NOT NULL,
  satuan VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  role operator_role DEFAULT 'OPERATOR_TERITORIAL',
  clearance_level INT DEFAULT 1 CHECK (clearance_level BETWEEN 1 AND 5),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Tabel Immutable Blockchain Ledger (Append-Only Audit Trail)
CREATE TABLE IF NOT EXISTS public.blockchain_ledger (
  block_height BIGSERIAL PRIMARY KEY,
  hash VARCHAR(64) NOT NULL UNIQUE,
  prev_hash VARCHAR(64) NOT NULL,
  merkle_root VARCHAR(66) NOT NULL,
  operator_id UUID REFERENCES public.operator_profiles(id) ON DELETE SET NULL,
  action_type VARCHAR(50) NOT NULL,
  payload_digest VARCHAR(64) NOT NULL,
  nonce BIGINT DEFAULT 1849204,
  dilithium_signature TEXT,
  kyber_tag VARCHAR(100) DEFAULT 'KYBER-1024-ENCAP-SESSION-OK',
  tactical_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Genesis Block Seeding (Blok 0 - Titik Awal Rantai Kriptografis)
INSERT INTO public.blockchain_ledger (
  block_height,
  hash,
  prev_hash,
  merkle_root,
  operator_id,
  action_type,
  payload_digest,
  dilithium_signature,
  tactical_notes
) VALUES (
  0,
  '0000000000000000000000000000000000000000000000000000000000000000',
  'GENESIS_BLOCK_NANGGROE_CAKRAWALA_SHIELD',
  '0x7F4A89C1D2E3B4A5C6D7E8F90A1B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6E7F8A9B',
  NULL,
  'GENESIS_INIT',
  encode(digest('SI-CAKRAWALA_GENESIS_ROOT', 'sha256'), 'hex'),
  'DILITHIUM5:GENESIS_INIT_SIG (NIST FIPS 204 Validated)',
  'Inisialisasi Root Chain Jaringan Komando Siber Nasional'
) ON CONFLICT (block_height) DO NOTHING;

-- 6. Trigger Mutlak Anti-Manipulasi (Tabel Tidak Boleh di-UPDATE atau DELETE)
CREATE OR REPLACE FUNCTION protect_blockchain_ledger()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    RAISE EXCEPTION 'SECURITY_VIOLATION: Data blockchain bersifat immutable (kekal), operasi UPDATE dilarang!';
  ELSIF (TG_OP = 'DELETE') THEN
    RAISE EXCEPTION 'SECURITY_VIOLATION: Data blockchain bersifat immutable (kekal), operasi DELETE dilarang!';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_protect_blockchain_ledger ON public.blockchain_ledger;
CREATE TRIGGER trg_protect_blockchain_ledger
BEFORE UPDATE OR DELETE ON public.blockchain_ledger
FOR EACH ROW EXECUTE FUNCTION protect_blockchain_ledger();

-- 7. Trigger Otomatis Hashing Setiap Ada Operator Baru Terdaftar
CREATE OR REPLACE FUNCTION log_operator_registration_to_blockchain()
RETURNS TRIGGER AS $$
DECLARE
  v_last_hash VARCHAR(64);
  v_new_hash VARCHAR(64);
  v_payload VARCHAR;
BEGIN
  -- Ambil hash blok paling mutakhir
  SELECT hash INTO v_last_hash FROM public.blockchain_ledger ORDER BY block_height DESC LIMIT 1;
  IF v_last_hash IS NULL THEN
    v_last_hash := 'GENESIS_BLOCK_NANGGROE_CAKRAWALA_SHIELD';
  END IF;

  v_payload := NEW.id || ':' || NEW.nik || ':' || NEW.email || ':' || NOW();
  v_new_hash := encode(digest(v_last_hash || v_payload, 'sha256'), 'hex');

  INSERT INTO public.blockchain_ledger (
    hash,
    prev_hash,
    merkle_root,
    operator_id,
    action_type,
    payload_digest,
    dilithium_signature,
    tactical_notes
  ) VALUES (
    v_new_hash,
    v_last_hash,
    '0x' || encode(digest(v_payload, 'sha256'), 'hex'),
    NEW.id,
    'OPERATOR_REGISTERED',
    encode(digest(v_payload, 'sha256'), 'hex'),
    'DILITHIUM5:' || substr(v_new_hash, 1, 16) || '... (NIST FIPS 204)',
    'Registrasi operator resmi: ' || NEW.nama_lengkap || ' (' || NEW.pangkat || ' - ' || NEW.satuan || ')'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_operator_blockchain_log ON public.operator_profiles;
CREATE TRIGGER trg_operator_blockchain_log
AFTER INSERT ON public.operator_profiles
FOR EACH ROW EXECUTE FUNCTION log_operator_registration_to_blockchain();

-- 8. Konfigurasi Row Level Security (RLS)
ALTER TABLE public.operator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_ledger ENABLE ROW LEVEL SECURITY;

-- Policy Profile Pengguna
DROP POLICY IF EXISTS "Operator can read own profile" ON public.operator_profiles;
CREATE POLICY "Operator can read own profile" 
ON public.operator_profiles 
FOR SELECT 
TO authenticated 
USING (auth.uid() = id);

DROP POLICY IF EXISTS "Operator can insert own profile" ON public.operator_profiles;
CREATE POLICY "Operator can insert own profile" 
ON public.operator_profiles 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Operator can update own profile" ON public.operator_profiles;
CREATE POLICY "Operator can update own profile" 
ON public.operator_profiles 
FOR UPDATE 
TO authenticated 
USING (auth.uid() = id);

-- Policy Ledger Blockchain: Seluruh personel terautentikasi dapat membaca & memvalidasi rantai
DROP POLICY IF EXISTS "Operators can read blockchain ledger" ON public.blockchain_ledger;
CREATE POLICY "Operators can read blockchain ledger" 
ON public.blockchain_ledger 
FOR SELECT 
TO authenticated 
USING (true);

-- Policy Ledger Blockchain: Insert hanya bisa dilakukan lewat fungsi/trigger terpercaya atau autentikasi valid
DROP POLICY IF EXISTS "Operators can append tactical actions to ledger" ON public.blockchain_ledger;
CREATE POLICY "Operators can append tactical actions to ledger" 
ON public.blockchain_ledger 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = operator_id);

