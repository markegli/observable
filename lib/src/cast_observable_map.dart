import 'package:collection/collection.dart';

import 'records.dart';
import 'observable_map.dart';

/// A view of an [ObservableMap] as a map of [K] keys and [V] values.
///
/// Any change made to the original map will be reported on this map (and vice
/// versa), assuming the keys and values have types [K] and [V] respectively.
class CastObservableMap<BK, BV, K, V> extends DelegatingMap<K, V>
    implements ObservableMap<K, V> {
  /// Casts every [MapChangeRecord] in [changes] to [MapChangeRecord<K, V>].
  static List<ChangeRecord> _castChanges<K, V>(List<ChangeRecord> changes) => [
        for (var change in changes)
          change is MapChangeRecord
              ? MapChangeRecord<K, V>(
                  change.key, change.oldValue, change.newValue)
              : change,
      ];

  final ObservableMap<BK, BV> _baseMap;

  CastObservableMap.cast(ObservableMap<BK, BV> baseMap)
      : _baseMap = baseMap,
        super(Map.castFrom(baseMap));
  CastObservableMap.recast(CastObservableMap<BK, BV, dynamic, dynamic> other)
      : _baseMap = other._baseMap,
        super(Map.castFrom(other._baseMap));

  @override
  ObservableMap<RK, RV> cast<RK, RV>() =>
      CastObservableMap<BK, BV, RK, RV>.recast(this);

  @deprecated
  @override
  // ignore: override_on_non_overriding_method
  ObservableMap<RK, RV> retype<RK, RV>() => cast<RK, RV>();

  Stream<List<ChangeRecord>> _changes;

  @override
  Stream<List<ChangeRecord>> get changes => _changes ??=
      _baseMap.changes.map((changes) => _castChanges<K, V>(changes));

  @deprecated
  @override
  bool deliverChanges() => _baseMap.deliverChanges();

  @deprecated
  @override
  bool get hasObservers => _baseMap.hasObservers;

  @deprecated
  @override
  void notifyChange([ChangeRecord change]) => _baseMap.notifyChange(change);

  @deprecated
  @override
  T notifyPropertyChange<T>(Symbol field, T oldValue, T newValue) =>
      _baseMap.notifyPropertyChange(field, oldValue, newValue);

  @deprecated
  @override
  void observed() => _baseMap.observed();

  @deprecated
  @override
  void unobserved() => _baseMap.unobserved();
}
