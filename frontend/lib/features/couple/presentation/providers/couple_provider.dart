import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/core_providers.dart';
import '../../data/couple_repository.dart';

final coupleRepositoryProvider = Provider((ref) => CoupleRepository(ref.watch(dioProvider)));
