import 'package:collection/collection.dart';

import 'records.dart';
import 'observable_list.dart';

/// A view of an [ObservableList] as a list of [E] instances.
///
/// Any change made to the original list will be reported on this list (and vice
/// versa), assuming the elements added or removed have type [E].
class CastObservableList<B, E> extends DelegatingList<E>
    implements ObservableList<E> {
  /// Casts all [changes] to [ListChangeRecord<E>].
  static List<ListChangeRecord<E>> _castChanges<E>(
          Iterable<ListChangeRecord> changes, ObservableList<E> list) =>
      [
        for (var change in changes)
          ListChangeRecord<E>(list, change.index,
              removed: change.removed.cast<E>(), addedCount: change.addedCount),
      ];

  final ObservableList<B> _baseList;

  Stream<List<ListChangeRecord<E>>> _listChanges;

  CastObservableList.cast(ObservableList<B> baseList)
      : _baseList = baseList,
        super(List.castFrom<B, E>(baseList));
  CastObservableList.recast(CastObservableList<B, dynamic> other)
      : _baseList = other._baseList,
        super(List.castFrom<B, E>(other._baseList));

  @override
  ObservableList<R> cast<R>() => CastObservableList<B, R>.recast(this);

  @deprecated
  @override
  // ignore: override_on_non_overriding_method
  ObservableList<T> retype<T>() => cast<T>();

  @override
  int indexOf(Object element, [int start = 0]) =>
      _baseList.indexOf(element, start);

  @override
  int lastIndexOf(Object element, [int start]) =>
      _baseList.lastIndexOf(element, start);

  @override
  Stream<List<ChangeRecord>> get changes => _baseList.changes;

  @override
  Stream<List<ListChangeRecord<E>>> get listChanges => _listChanges ??=
      _baseList.listChanges.map((changes) => _castChanges<E>(changes, this));

  @override
  bool deliverListChanges() => _baseList.deliverListChanges();

  @override
  void discardListChanges() => _baseList.discardListChanges();

  @deprecated
  @override
  bool get hasObservers => _baseList.hasObservers;

  @override
  bool get hasListObservers => _baseList.hasListObservers;

  @deprecated
  @override
  bool deliverChanges() => _baseList.deliverChanges();

  @deprecated
  @override
  void notifyChange([ChangeRecord change]) => _baseList.notifyChange(change);

  @deprecated
  @override
  T notifyPropertyChange<T>(Symbol field, T oldValue, T newValue) =>
      _baseList.notifyPropertyChange(field, oldValue, newValue);

  @deprecated
  @override
  void observed() => _baseList.observed();

  @deprecated
  @override
  void unobserved() => _baseList.unobserved();
}
