-- ==============================================================================
-- SI-CAKRAWALA — DATA DUMMY UNTUK JURI / REVIEWER
-- Eksekusi di Supabase SQL Editor SETELAH menjalankan supabase_schema.sql
-- ==============================================================================
-- Catatan: Supabase Auth tidak mendukung INSERT langsung ke auth.users via SQL.
-- Gunakan akun di bawah ini yang sudah pre-registered via UI website:
-- Semua password menggunakan format: [NAMAUSER]@Siber2045
-- 
-- CARA PENGGUNAAN:
-- 1. Jalankan supabase_schema.sql terlebih dahulu (skema utama)
-- 2. Daftarkan 4 akun di bawah via halaman Daftar Sekarang di website
-- 3. Jalankan skrip UPDATE di bawah untuk mengupgrade role & status akun
-- ==============================================================================

-- LANGKAH AKHIR: Setelah akun dibuat via website, jalankan UPDATE berikut
-- untuk memberikan akses privilege sesuai peran masing-masing juri.
-- Ganti {EMAIL_TERDAFTAR} dengan email yang dipakai saat mendaftar.

-- ─────────────────────────────────────────────────────────────────────────────
-- AKUN 1 — ADMIN SISTEM (Akses Penuh Nasional / Pusat)
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.operator_profiles
SET
  role = 'ADMIN_SISTEM',
  verification_status = 'APPROVED_ACTIVE',
  regional_command = 'MABES SATSIBER TNI AD',
  clearance_level = 5,
  verified_at = NOW()
WHERE nik = 'JURI001';

-- ─────────────────────────────────────────────────────────────────────────────
-- AKUN 2 — PANGLIMA WILAYAH (Jenderal Kodam Jaya — Wilayah DKI Jakarta)
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.operator_profiles
SET
  role = 'PANGLIMA_WILAYAH',
  verification_status = 'APPROVED_ACTIVE',
  regional_command = 'Kodam Jaya',
  clearance_level = 4,
  verified_at = NOW()
WHERE nik = 'JURI002';

-- ─────────────────────────────────────────────────────────────────────────────
-- AKUN 3 — KOMANDAN SATSIBER (Akses Strategis Nasional)
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.operator_profiles
SET
  role = 'KOMANDAN_SATSIBER',
  verification_status = 'APPROVED_ACTIVE',
  regional_command = 'MABES SATSIBER TNI AD',
  clearance_level = 5,
  verified_at = NOW()
WHERE nik = 'JURI003';

-- ─────────────────────────────────────────────────────────────────────────────
-- AKUN 4 — OPERATOR TERITORIAL (Personel Lapangan — Simulasi Pending)
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE public.operator_profiles
SET
  role = 'OPERATOR_TERITORIAL',
  verification_status = 'PENDING_VERIFICATION',
  regional_command = 'Kodam Jaya',
  clearance_level = 1
WHERE nik = 'JURI004';

-- ─────────────────────────────────────────────────────────────────────────────
-- SEED LOG AKTIVITAS DUMMY (opsional — untuk memperlihatkan tampilan monitor)
-- Jalankan setelah JURI001 login minimal sekali agar operator_id valid
-- ─────────────────────────────────────────────────────────────────────────────
INSERT INTO public.user_activity_logs (operator_id, operator_nik, operator_name, regional_command, activity_type, action_detail, severity_level)
SELECT id, nik, nama_lengkap, regional_command, 'LOGIN', 'Personel berhasil masuk sistem Pusat Komando (Clearance Level: 5)', 'INFO'
FROM public.operator_profiles WHERE nik = 'JURI001'
ON CONFLICT DO NOTHING;

INSERT INTO public.user_activity_logs (operator_id, operator_nik, operator_name, regional_command, activity_type, action_detail, target_node_id, severity_level)
SELECT id, nik, nama_lengkap, regional_command, 'RADAR_PROBE', 'Pemindaian status node radar di Sektor Natuna — Anomali terdeteksi', 'ID-KRI', 'WARN'
FROM public.operator_profiles WHERE nik = 'JURI001'
ON CONFLICT DO NOTHING;

INSERT INTO public.user_activity_logs (operator_id, operator_nik, operator_name, regional_command, activity_type, action_detail, target_node_id, severity_level)
SELECT id, nik, nama_lengkap, regional_command, 'OPERATOR_APPROVED', 'Persetujuan akun personel baru di wilayah Kodam Jaya (Clearance Level 2)', NULL, 'INFO'
FROM public.operator_profiles WHERE nik = 'JURI002'
ON CONFLICT DO NOTHING;

INSERT INTO public.user_activity_logs (operator_id, operator_nik, operator_name, regional_command, activity_type, action_detail, target_node_id, severity_level)
SELECT id, nik, nama_lengkap, regional_command, 'THREAT_ISOLATION', 'Isolasi APT-29 payload hash 0x415054 terdeteksi di Kodam VI/Mulawarman', 'ID-BALIKPAPAN', 'CRITICAL'
FROM public.operator_profiles WHERE nik = 'JURI003'
ON CONFLICT DO NOTHING;
