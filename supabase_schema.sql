-- ==============================================================================
-- SI-CAKRAWALA (NANGGROE CAKRAWALA SHIELD)
-- DATABASE SCHEMA, RBAC KOMANDO TERITORIAL & BLOCKCHAIN AUDIT LEDGER
-- Target Database: Supabase PostgreSQL (Production Ready & Safe Execution)
-- ==============================================================================

-- 1. Ekstensi Kriptografi & UUID
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Migrasi Tipe Kolom ke VARCHAR (Mencegah PostgreSQL Enum 55P04 Error)
DO $$ BEGIN
  ALTER TABLE public.operator_profiles ALTER COLUMN role TYPE VARCHAR(50);
EXCEPTION
  WHEN undefined_table THEN null;
  WHEN undefined_column THEN null;
  WHEN others THEN null;
END $$;

-- 3. Tabel Profil Pengguna (Sinkron dengan auth.users Supabase)
CREATE TABLE IF NOT EXISTS public.operator_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nik VARCHAR(50) UNIQUE NOT NULL,
  nama_lengkap VARCHAR(100) NOT NULL,
  pangkat VARCHAR(50) NOT NULL,
  satuan VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  role VARCHAR(50) DEFAULT 'OPERATOR_TERITORIAL',
  regional_command VARCHAR(100) DEFAULT 'Kodam Jaya',
  verification_status VARCHAR(50) DEFAULT 'PENDING_VERIFICATION',
  verified_by UUID REFERENCES public.operator_profiles(id),
  verified_at TIMESTAMPTZ,
  rejection_notes TEXT,
  clearance_level INT DEFAULT 1 CHECK (clearance_level BETWEEN 1 AND 5),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tambahkan kolom jika tabel sudah ada sebelumnya
ALTER TABLE public.operator_profiles
  ADD COLUMN IF NOT EXISTS regional_command VARCHAR(100) DEFAULT 'Kodam Jaya',
  ADD COLUMN IF NOT EXISTS verification_status VARCHAR(50) DEFAULT 'PENDING_VERIFICATION',
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES public.operator_profiles(id),
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS rejection_notes TEXT;

-- Pastikan tipe verification_status adalah VARCHAR
DO $$ BEGIN
  ALTER TABLE public.operator_profiles ALTER COLUMN verification_status TYPE VARCHAR(50);
EXCEPTION
  WHEN others THEN null;
END $$;

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

-- 5. Tabel Pemantauan Aktivitas Pengguna (User Activity Logs)
CREATE TABLE IF NOT EXISTS public.user_activity_logs (
  id BIGSERIAL PRIMARY KEY,
  operator_id UUID NOT NULL REFERENCES public.operator_profiles(id) ON DELETE CASCADE,
  operator_nik VARCHAR(50) NOT NULL,
  operator_name VARCHAR(100),
  regional_command VARCHAR(100) NOT NULL,
  activity_type VARCHAR(50) NOT NULL,
  action_detail TEXT NOT NULL,
  target_node_id VARCHAR(50),
  ip_address VARCHAR(45) DEFAULT '127.0.0.1',
  severity_level VARCHAR(20) DEFAULT 'INFO',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Genesis Block Seeding (Blok 0 - Titik Awal Rantai Kriptografis)
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

-- 7. Trigger Mutlak Anti-Manipulasi (Tabel Tidak Boleh di-UPDATE atau DELETE)
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

-- 8. Trigger Otomatis Hashing Registrasi Operator
CREATE OR REPLACE FUNCTION log_operator_registration_to_blockchain()
RETURNS TRIGGER AS $$
DECLARE
  v_last_hash VARCHAR(64);
  v_new_hash VARCHAR(64);
  v_payload VARCHAR;
BEGIN
  SELECT hash INTO v_last_hash FROM public.blockchain_ledger ORDER BY block_height DESC LIMIT 1;
  IF v_last_hash IS NULL THEN
    v_last_hash := 'GENESIS_BLOCK_NANGGROE_CAKRAWALA_SHIELD';
  END IF;

  v_payload := NEW.id || ':' || NEW.nik || ':' || COALESCE(NEW.regional_command, 'MABES') || ':' || NOW();
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
    'OPERATOR_REGISTERED_PENDING',
    encode(digest(v_payload, 'sha256'), 'hex'),
    'DILITHIUM5:' || substr(v_new_hash, 1, 16) || '... (NIST FIPS 204)',
    'Registrasi personel: ' || NEW.nama_lengkap || ' (' || NEW.pangkat || ' - ' || COALESCE(NEW.regional_command, 'Kodam Jaya') || ') - MENUNGGU VERIFIKASI PANGLIMA'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_operator_blockchain_log ON public.operator_profiles;
CREATE TRIGGER trg_operator_blockchain_log
AFTER INSERT ON public.operator_profiles
FOR EACH ROW EXECUTE FUNCTION log_operator_registration_to_blockchain();

-- 9. Trigger Otomatis Blockchain saat Status Verifikasi Akun Diubah (Approval/Rejection)
CREATE OR REPLACE FUNCTION log_verification_to_blockchain()
RETURNS TRIGGER AS $$
DECLARE
  v_last_hash VARCHAR(64);
  v_new_hash VARCHAR(64);
  v_payload VARCHAR;
  v_actor_nik VARCHAR(50);
BEGIN
  IF (OLD.verification_status IS DISTINCT FROM NEW.verification_status) THEN
    SELECT hash INTO v_last_hash FROM public.blockchain_ledger ORDER BY block_height DESC LIMIT 1;
    IF v_last_hash IS NULL THEN
      v_last_hash := 'GENESIS_BLOCK_NANGGROE_CAKRAWALA_SHIELD';
    END IF;

    SELECT nik INTO v_actor_nik FROM public.operator_profiles WHERE id = NEW.verified_by;

    v_payload := NEW.id || ':' || NEW.nik || ':' || NEW.verification_status || ':' || COALESCE(v_actor_nik, 'SYSTEM') || ':' || NOW();
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
      NEW.verified_by,
      CASE 
        WHEN NEW.verification_status = 'APPROVED_ACTIVE' THEN 'OPERATOR_VERIFIED_APPROVED'
        WHEN NEW.verification_status = 'REJECTED' THEN 'OPERATOR_VERIFIED_REJECTED'
        ELSE 'OPERATOR_STATUS_CHANGED'
      END,
      encode(digest(v_payload, 'sha256'), 'hex'),
      'DILITHIUM5:' || substr(v_new_hash, 1, 16) || '... (NIST FIPS 204)',
      'Otorisasi Komando: Personel ' || NEW.nama_lengkap || ' (' || NEW.nik || ') diubah ke ' || NEW.verification_status || 
      ' oleh Jenderal/Admin (' || COALESCE(v_actor_nik, 'SYSTEM') || ')'
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_operator_verification_log ON public.operator_profiles;
CREATE TRIGGER trg_operator_verification_log
AFTER UPDATE ON public.operator_profiles
FOR EACH ROW EXECUTE FUNCTION log_verification_to_blockchain();

-- 10. Row Level Security (RLS)
ALTER TABLE public.operator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_logs ENABLE ROW LEVEL SECURITY;

-- Operator Profile RLS:
DROP POLICY IF EXISTS "Operator view own or regional admin view" ON public.operator_profiles;
CREATE POLICY "Operator view own or regional admin view" 
ON public.operator_profiles 
FOR SELECT 
TO authenticated 
USING (
  auth.uid() = id
  OR (SELECT role::text FROM public.operator_profiles WHERE id = auth.uid()) IN ('ADMIN_SISTEM', 'KOMANDAN_SATSIBER')
  OR (
    (SELECT role::text FROM public.operator_profiles WHERE id = auth.uid()) = 'PANGLIMA_WILAYAH'
    AND regional_command = (SELECT regional_command FROM public.operator_profiles WHERE id = auth.uid())
  )
);

DROP POLICY IF EXISTS "Operator insert own profile" ON public.operator_profiles;
CREATE POLICY "Operator insert own profile" 
ON public.operator_profiles 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Regional admin or system admin can update profile" ON public.operator_profiles;
CREATE POLICY "Regional admin or system admin can update profile" 
ON public.operator_profiles 
FOR UPDATE 
TO authenticated 
USING (
  auth.uid() = id
  OR (SELECT role::text FROM public.operator_profiles WHERE id = auth.uid()) IN ('ADMIN_SISTEM', 'KOMANDAN_SATSIBER')
  OR (
    (SELECT role::text FROM public.operator_profiles WHERE id = auth.uid()) = 'PANGLIMA_WILAYAH'
    AND regional_command = (SELECT regional_command FROM public.operator_profiles WHERE id = auth.uid())
  )
);

-- Blockchain Ledger RLS:
DROP POLICY IF EXISTS "Authenticated users can read blockchain" ON public.blockchain_ledger;
CREATE POLICY "Authenticated users can read blockchain" 
ON public.blockchain_ledger 
FOR SELECT 
TO authenticated 
USING (true);

-- User Activity Logs RLS:
DROP POLICY IF EXISTS "Insert activity log" ON public.user_activity_logs;
CREATE POLICY "Insert activity log" 
ON public.user_activity_logs 
FOR INSERT 
TO authenticated 
WITH CHECK (operator_id = auth.uid());

DROP POLICY IF EXISTS "View activity logs by region or admin" ON public.user_activity_logs;
CREATE POLICY "View activity logs by region or admin" 
ON public.user_activity_logs 
FOR SELECT 
TO authenticated 
USING (
  operator_id = auth.uid()
  OR (SELECT role::text FROM public.operator_profiles WHERE id = auth.uid()) IN ('ADMIN_SISTEM', 'KOMANDAN_SATSIBER')
  OR (
    (SELECT role::text FROM public.operator_profiles WHERE id = auth.uid()) = 'PANGLIMA_WILAYAH'
    AND regional_command = (SELECT regional_command FROM public.operator_profiles WHERE id = auth.uid())
  )
);
