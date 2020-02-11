// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: deprecated_member_use_from_same_package
library observable.src.collections.observable_map;

import 'dart:collection';

import 'package:observable/observable.dart';
import 'cast_observable_map.dart';

// TODO(jmesserly): this needs to be faster. We currently require multiple
// lookups per key to get the old value.
// TODO(jmesserly): this doesn't implement the precise interfaces like
// LinkedHashMap, SplayTreeMap or HashMap. However it can use them for the
// backing store.

/// Represents an observable map of model values. If any items are added,
/// removed, or replaced, then observers that are listening to [changes]
/// will be notified.
class ObservableMap<K, V> extends Observable implements Map<K, V> {
  /// Adapts [source] to be a `ObservableMap<K2, V2>`.
  ///
  /// Any time the map would produce a key or value that is not a [K2] or [V2]
  /// the access will throw.
  ///
  /// Any time [K2] key or [V2] value is attempted added into the adapted map,
  /// the store will throw unless the key is also an instance of [K] and the
  /// value is also an instance of [V].
  ///
  /// If all accessed entries of [source] have [K2] keys and [V2] values and if
  /// all entries added to the returned map have [K] keys and [V] values, then
  /// the returned map can be used as a `Map<K2, V2>`.
  static ObservableMap<K2, V2> castFrom<K, V, K2, V2>(
          ObservableMap<K, V> source) =>
      source.cast<K2, V2>();

  final Map<K, V> _map;

  /// Creates an observable map.
  ObservableMap() : _map = HashMap<K, V>();

  /// Creates a new observable map using a [LinkedHashMap].
  ObservableMap.linked() : _map = <K, V>{};

  /// Creates a new observable map using a [SplayTreeMap].
  ObservableMap.sorted() : _map = SplayTreeMap<K, V>();

  /// Creates an observable map that contains all key value pairs of [other].
  /// It will attempt to use the same backing map type if the other map is a
  /// [LinkedHashMap], [SplayTreeMap], or [HashMap]. Otherwise it defaults to
  /// [HashMap].
  ///
  /// Note this will perform a shallow conversion. If you want a deep conversion
  /// you should use [toObservable].
  factory ObservableMap.from(Map<K, V> other) {
    return ObservableMap<K, V>.createFromType(other)..addAll(other);
  }

  /// Like [ObservableMap.from], but creates an empty map.
  factory ObservableMap.createFromType(Map<K, V> other) {
    ObservableMap<K, V> result;
    if (other is SplayTreeMap) {
      result = ObservableMap<K, V>.sorted();
    } else if (other is LinkedHashMap) {
      result = ObservableMap<K, V>.linked();
    } else {
      result = ObservableMap<K, V>();
    }
    return result;
  }

  /// Creates a new observable map wrapping [other].
  ObservableMap.spy(Map<K, V> other) : _map = other;

  @override
  Iterable<K> get keys => _map.keys;

  @override
  Iterable<V> get values => _map.values;

  @override
  int get length => _map.length;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  bool containsValue(Object value) => _map.containsValue(value);

  @override
  bool containsKey(Object key) => _map.containsKey(key);

  @override
  V operator [](Object key) => _map[key];

  @override
  void operator []=(K key, V value) {
    if (!hasObservers) {
      _map[key] = value;
      return;
    }

    var len = _map.length;
    var oldValue = _map[key];

    _map[key] = value;

    if (len != _map.length) {
      notifyPropertyChange(#length, len, _map.length);
      notifyChange(MapChangeRecord.insert(key, value));
      _notifyKeysValuesChanged();
    } else if (oldValue != value) {
      notifyChange(MapChangeRecord(key, oldValue, value));
      _notifyValuesChanged();
    }
  }

  @override
  void addAll(Map<K, V> other) {
    other.forEach((K key, V value) {
      this[key] = value;
    });
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    var len = _map.length;
    var result = _map.putIfAbsent(key, ifAbsent);
    if (hasObservers && len != _map.length) {
      notifyPropertyChange(#length, len, _map.length);
      notifyChange(MapChangeRecord.insert(key, result));
      _notifyKeysValuesChanged();
    }
    return result;
  }

  @override
  V remove(Object key) {
    var len = _map.length;
    var result = _map.remove(key);
    if (hasObservers && len != _map.length) {
      notifyChange(MapChangeRecord.remove(key, result));
      notifyPropertyChange(#length, len, _map.length);
      _notifyKeysValuesChanged();
    }
    return result;
  }

  @override
  void clear() {
    var len = _map.length;
    if (hasObservers && len > 0) {
      _map.forEach((key, value) {
        notifyChange(MapChangeRecord.remove(key, value));
      });
      notifyPropertyChange(#length, len, 0);
      _notifyKeysValuesChanged();
    }
    _map.clear();
  }

  @override
  void forEach(void Function(K key, V value) f) => _map.forEach(f);

  @override
  String toString() => MapBase.mapToString(this);

  @override
  ObservableMap<K2, V2> cast<K2, V2>() =>
      CastObservableMap<K, V, K2, V2>.cast(this);

  @deprecated
  @override
  // ignore: override_on_non_overriding_method
  ObservableMap<K2, V2> retype<K2, V2>() => cast<K2, V2>();

  @override
  Iterable<MapEntry<K, V>> get entries => _map.entries;

  @override
  void addEntries(Iterable<MapEntry<K, V>> entries) {
    _map.addEntries(entries);
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) transform) {
    return _map.map(transform);
  }

  @override
  V update(K key, V Function(V value) update, {V Function() ifAbsent}) {
    return _map.update(key, update, ifAbsent: ifAbsent);
  }

  @override
  void updateAll(V Function(K key, V value) update) => _map.updateAll(update);

  @override
  void removeWhere(bool Function(K key, V value) test) =>
      _map.removeWhere(test);

  // Note: we don't really have a reasonable old/new value to use here.
  // But this should fix "keys" and "values" in templates with minimal overhead.
  void _notifyKeysValuesChanged() {
    notifyChange(PropertyChangeRecord(this, #keys, null, null));
    _notifyValuesChanged();
  }

  void _notifyValuesChanged() {
    notifyChange(PropertyChangeRecord(this, #values, null, null));
  }
}
