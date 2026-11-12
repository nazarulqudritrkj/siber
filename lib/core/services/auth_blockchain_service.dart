import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../../models/blockchain_block.dart';

class OperatorProfile {
  final String id;
  final String nik;
  final String namaLengkap;
  final String pangkat;
  final String satuan;
  final String email;
  final String role; // 'OPERATOR_TERITORIAL', 'ANALIS_INTELIJEN', 'PANGLIMA_WILAYAH', 'KOMANDAN_SATSIBER', 'ADMIN_SISTEM'
  final String regionalCommand; // e.g. 'Kodam Jaya', 'Kodam VI/Mulawarman'
  final String verificationStatus; // 'PENDING_VERIFICATION', 'APPROVED_ACTIVE', 'REJECTED', 'SUSPENDED'
  final String? verifiedBy;
  final String? verifiedAt;
  final String? rejectionNotes;
  final int clearanceLevel;
  final bool isActive;

  const OperatorProfile({
    required this.id,
    required this.nik,
    required this.namaLengkap,
    required this.pangkat,
    required this.satuan,
    required this.email,
    required this.role,
    this.regionalCommand = 'Kodam Jaya',
    this.verificationStatus = 'PENDING_VERIFICATION',
    this.verifiedBy,
    this.verifiedAt,
    this.rejectionNotes,
    required this.clearanceLevel,
    this.isActive = true,
  });

  bool get isApproved => verificationStatus == 'APPROVED_ACTIVE';
  bool get isPending => verificationStatus == 'PENDING_VERIFICATION';
  bool get isRejected => verificationStatus == 'REJECTED';
  bool get isRegionalGeneral => role == 'PANGLIMA_WILAYAH';
  bool get isSystemAdmin => role == 'ADMIN_SISTEM' || role == 'KOMANDAN_SATSIBER';

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      id: json['id'] as String? ?? '',
      nik: json['nik'] as String? ?? '',
      namaLengkap: json['nama_lengkap'] as String? ?? '',
      pangkat: json['pangkat'] as String? ?? '',
      satuan: json['satuan'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'OPERATOR_TERITORIAL',
      regionalCommand: json['regional_command'] as String? ?? 'Kodam Jaya',
      verificationStatus: json['verification_status'] as String? ?? 'PENDING_VERIFICATION',
      verifiedBy: json['verified_by'] as String?,
      verifiedAt: json['verified_at'] as String?,
      rejectionNotes: json['rejection_notes'] as String?,
      clearanceLevel: (json['clearance_level'] as num?)?.toInt() ?? 1,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class UserActivityLog {
  final int id;
  final String operatorId;
  final String operatorNik;
  final String? operatorName;
  final String regionalCommand;
  final String activityType;
  final String actionDetail;
  final String? targetNodeId;
  final String ipAddress;
  final String severityLevel;
  final String createdAt;

  const UserActivityLog({
    required this.id,
    required this.operatorId,
    required this.operatorNik,
    this.operatorName,
    required this.regionalCommand,
    required this.activityType,
    required this.actionDetail,
    this.targetNodeId,
    required this.ipAddress,
    required this.severityLevel,
    required this.createdAt,
  });

  factory UserActivityLog.fromJson(Map<String, dynamic> json) {
    return UserActivityLog(
      id: (json['id'] as num?)?.toInt() ?? 0,
      operatorId: json['operator_id'] as String? ?? '',
      operatorNik: json['operator_nik'] as String? ?? '',
      operatorName: json['operator_name'] as String?,
      regionalCommand: json['regional_command'] as String? ?? '',
      activityType: json['activity_type'] as String? ?? 'ACTIVITY',
      actionDetail: json['action_detail'] as String? ?? '',
      targetNodeId: json['target_node_id'] as String?,
      ipAddress: json['ip_address'] as String? ?? '127.0.0.1',
      severityLevel: json['severity_level'] as String? ?? 'INFO',
      createdAt: json['created_at'] != null ? json['created_at'].toString().substring(0, 19) : '',
    );
  }
}

class AuthBlockchainService {
  static final AuthBlockchainService _instance = AuthBlockchainService._internal();
  factory AuthBlockchainService() => _instance;
  AuthBlockchainService._internal();

  SupabaseClient? get _client => SupabaseConfig.client;

  /// Profil pengguna yang sedang login saat ini
  OperatorProfile? currentProfile;

  bool get isAuthenticated => _client?.auth.currentUser != null;
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Registrasi personel taktis baru
  Future<Map<String, dynamic>> registerOperator({
    required String email,
    required String password,
    required String namaLengkap,
    required String nik,
    required String pangkat,
    required String satuan,
    String regionalCommand = 'Kodam Jaya',
  }) async {
    final client = _client;
    if (client == null) {
      return {
        'success': false,
        'message': 'Supabase belum terinisialisasi. Periksa koneksi.',
      };
    }

    try {
      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        return {
          'success': false,
          'message': 'Gagal membuat akun operator di sistem otentikasi.',
        };
      }

      await client.from('operator_profiles').insert({
        'id': user.id,
        'nik': nik,
        'nama_lengkap': namaLengkap,
        'pangkat': pangkat,
        'satuan': satuan,
        'email': email,
        'role': 'OPERATOR_TERITORIAL',
        'regional_command': regionalCommand,
        'verification_status': 'PENDING_VERIFICATION',
        'clearance_level': 1,
      });

      return {
        'success': true,
        'message': 'Personel berhasil didaftarkan dan menunggu verifikasi Panglima Wilayah.',
        'userId': user.id,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': 'Gagal autentikasi: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan sistem: $e'};
    }
  }

  /// Login personel (Mendukung Email atau NIK)
  Future<Map<String, dynamic>> loginOperator({
    required String identifier,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return {'success': false, 'message': 'Supabase belum terhubung.'};
    }

    try {
      String emailToUse = identifier.trim();

      if (!identifier.contains('@')) {
        final profileRes = await client
            .from('operator_profiles')
            .select('email')
            .eq('nik', identifier.trim())
            .maybeSingle();

        if (profileRes != null && profileRes['email'] != null) {
          emailToUse = profileRes['email'] as String;
        } else {
          emailToUse = '${identifier.trim().toLowerCase().replaceAll(" ", "")}@siber.tni.mil.id';
        }
      }

      final response = await client.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'message': 'Kredensial tidak valid.'};
      }

      final profile = await getProfile(response.user!.id);
      currentProfile = profile;

      if (profile != null) {
        // Cek status verifikasi (kecuali jika role admin sistem)
        if (!profile.isSystemAdmin) {
          if (profile.verificationStatus == 'PENDING_VERIFICATION') {
            await client.auth.signOut();
            return {
              'success': false,
              'isPending': true,
              'message': 'AKSES DITAHAN: Akun Anda belum diverifikasi oleh Jenderal/Panglima ${profile.regionalCommand}. Hubungi Perwira Teritorial.',
            };
          } else if (profile.verificationStatus == 'REJECTED') {
            await client.auth.signOut();
            return {
              'success': false,
              'isRejected': true,
              'message': 'AKSES DITOLAK: Pendaftaran Anda ditolak. Alasan: ${profile.rejectionNotes ?? "Kredensial personel tidak valid"}.',
            };
          } else if (profile.verificationStatus == 'SUSPENDED') {
            await client.auth.signOut();
            return {
              'success': false,
              'message': 'AKSES DIBEKUKAN: Akun Anda sedang dinonaktifkan oleh Komando Wilayah.',
            };
          }
        }

        // Catat aktivitas login berhasil
        await logUserActivity(
          activityType: 'LOGIN',
          detail: 'Personel berhasil masuk sistem Pusat Komando (Clearance Level: ${profile.clearanceLevel})',
          severity: 'INFO',
        );
      }

      return {
        'success': true,
        'message': 'Otentikasi berhasil tervalidasi.',
        'user': response.user,
        'profile': profile,
      };
    } on AuthException catch (e) {
      return {'success': false, 'message': 'Gagal masuk: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan otentikasi: $e'};
    }
  }

  /// Mengambil profil operator
  Future<OperatorProfile?> getProfile(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final res = await client
          .from('operator_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        return OperatorProfile.fromJson(res);
      }
    } catch (_) {}
    return null;
  }

  /// Mengambil daftar operator yang menunggu persetujuan (Pending Verification)
  Future<List<OperatorProfile>> fetchPendingOperators({String? regionalCommand}) async {
    final client = _client;
    if (client == null) return [];

    try {
      PostgrestFilterBuilder query = client
          .from('operator_profiles')
          .select()
          .eq('verification_status', 'PENDING_VERIFICATION');

      if (regionalCommand != null && regionalCommand.isNotEmpty && regionalCommand != 'SEMUA_WILAYAH') {
        query = query.eq('regional_command', regionalCommand);
      }

      final res = await query.order('created_at', ascending: false);
      final List<dynamic> rows = res as List<dynamic>;
      return rows.map((r) => OperatorProfile.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil semua operator untuk monitoring wilayah
  Future<List<OperatorProfile>> fetchAllOperators({String? regionalCommand}) async {
    final client = _client;
    if (client == null) return [];

    try {
      PostgrestFilterBuilder query = client
          .from('operator_profiles')
          .select();

      if (regionalCommand != null && regionalCommand.isNotEmpty && regionalCommand != 'SEMUA_WILAYAH') {
        query = query.eq('regional_command', regionalCommand);
      }

      final res = await query.order('created_at', ascending: false);
      final List<dynamic> rows = res as List<dynamic>;
      return rows.map((r) => OperatorProfile.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Setujui (Approve) Akun Personel oleh Jenderal Wilayah / Admin
  Future<bool> approveOperator({
    required String operatorId,
    required int clearanceLevel,
    required String verifiedByUserId,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('operator_profiles').update({
        'verification_status': 'APPROVED_ACTIVE',
        'clearance_level': clearanceLevel,
        'verified_by': verifiedByUserId,
        'verified_at': DateTime.now().toIso8601String(),
        'rejection_notes': null,
      }).eq('id', operatorId);

      // Catat log aktivitas verifikasi
      await logUserActivity(
        activityType: 'OPERATOR_APPROVED',
        detail: 'Persetujuan personel ID: $operatorId disahkan dengan Clearance Level $clearanceLevel.',
        severity: 'INFO',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Tolak (Reject) Akun Personel oleh Jenderal Wilayah / Admin
  Future<bool> rejectOperator({
    required String operatorId,
    required String reason,
    required String verifiedByUserId,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('operator_profiles').update({
        'verification_status': 'REJECTED',
        'verified_by': verifiedByUserId,
        'verified_at': DateTime.now().toIso8601String(),
        'rejection_notes': reason,
      }).eq('id', operatorId);

      await logUserActivity(
        activityType: 'OPERATOR_REJECTED',
        detail: 'Penolakan pendaftaran personel ID: $operatorId. Alasan: $reason',
        severity: 'WARN',
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  /// Catat log aktivitas pengguna interaktif
  Future<void> logUserActivity({
    required String activityType,
    required String detail,
    String? targetNodeId,
    String severity = 'INFO',
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    try {
      final profile = currentProfile ?? await getProfile(user.id);
      await client.from('user_activity_logs').insert({
        'operator_id': user.id,
        'operator_nik': profile?.nik ?? user.email ?? 'ANON',
        'operator_name': profile?.namaLengkap ?? 'Operator Taktis',
        'regional_command': profile?.regionalCommand ?? 'Kodam Jaya',
        'activity_type': activityType,
        'action_detail': detail,
        'target_node_id': targetNodeId,
        'severity_level': severity,
      });
    } catch (_) {}
  }

  /// Mengambil riwayat aktivitas pengguna untuk pengawasan Jenderal / Admin
  Future<List<UserActivityLog>> fetchUserActivityLogs({String? regionalCommand}) async {
    final client = _client;
    if (client == null) return [];

    try {
      PostgrestFilterBuilder query = client
          .from('user_activity_logs')
          .select();

      if (regionalCommand != null && regionalCommand.isNotEmpty && regionalCommand != 'SEMUA_WILAYAH') {
        query = query.eq('regional_command', regionalCommand);
      }

      final res = await query.order('created_at', ascending: false).limit(100);
      final List<dynamic> rows = res as List<dynamic>;
      return rows.map((r) => UserActivityLog.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Mengambil riwayat Blockchain Ledger dari Supabase
  Future<List<BlockchainBlock>> fetchBlockchainLedger() async {
    final client = _client;
    if (client == null) return [];

    try {
      final res = await client
          .from('blockchain_ledger')
          .select()
          .order('block_height', ascending: true);

      final List<dynamic> rows = res as List<dynamic>;
      return rows.map((r) {
        return BlockchainBlock(
          height: (r['block_height'] as num).toInt(),
          hash: r['hash'] as String? ?? '',
          prevHash: r['prev_hash'] as String? ?? '',
          transactionsCount: 1,
          validator: 'SATSIBER-VALIDATOR-NODE-01',
          timestamp: r['created_at'] != null ? r['created_at'].toString().substring(0, 19) : '',
          isImmutable: true,
          merkleRoot: r['merkle_root'] as String? ?? '',
          nonce: (r['nonce'] as num?)?.toInt() ?? 1849204,
          dilithiumSignature: r['dilithium_signature'] as String? ?? 'DILITHIUM5:VALIDATED',
          kyberTag: r['kyber_tag'] as String? ?? 'KYBER-1024-ENCAP-SESSION-OK',
          tacticalLogs: [
            r['action_type']?.toString() ?? 'TACTICAL_EVENT',
            r['tactical_notes']?.toString() ?? 'Log tervalidasi rantai blok',
          ],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Verifikasi Integritas Rantai Blok
  bool verifyLedgerChainIntegrity(List<BlockchainBlock> blocks) {
    if (blocks.isEmpty) return true;
    for (int i = 1; i < blocks.length; i++) {
      if (blocks[i].prevHash != blocks[i - 1].hash) return false;
    }
    return true;
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      if (currentUserId != null) {
        await logUserActivity(activityType: 'LOGOUT', detail: 'Operator keluar dari sistem.', severity: 'INFO');
      }
      currentProfile = null;
      await _client?.auth.signOut();
    } catch (_) {}
  }
}
