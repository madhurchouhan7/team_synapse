// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'on_boarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApplianceLocalState {

 String get usageLevel; int get count; Map<String, String> get selectedDropdowns; bool get isExpanded;
/// Create a copy of ApplianceLocalState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplianceLocalStateCopyWith<ApplianceLocalState> get copyWith => _$ApplianceLocalStateCopyWithImpl<ApplianceLocalState>(this as ApplianceLocalState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplianceLocalState&&(identical(other.usageLevel, usageLevel) || other.usageLevel == usageLevel)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other.selectedDropdowns, selectedDropdowns)&&(identical(other.isExpanded, isExpanded) || other.isExpanded == isExpanded));
}


@override
int get hashCode => Object.hash(runtimeType,usageLevel,count,const DeepCollectionEquality().hash(selectedDropdowns),isExpanded);

@override
String toString() {
  return 'ApplianceLocalState(usageLevel: $usageLevel, count: $count, selectedDropdowns: $selectedDropdowns, isExpanded: $isExpanded)';
}


}

/// @nodoc
abstract mixin class $ApplianceLocalStateCopyWith<$Res>  {
  factory $ApplianceLocalStateCopyWith(ApplianceLocalState value, $Res Function(ApplianceLocalState) _then) = _$ApplianceLocalStateCopyWithImpl;
@useResult
$Res call({
 String usageLevel, int count, Map<String, String> selectedDropdowns, bool isExpanded
});




}
/// @nodoc
class _$ApplianceLocalStateCopyWithImpl<$Res>
    implements $ApplianceLocalStateCopyWith<$Res> {
  _$ApplianceLocalStateCopyWithImpl(this._self, this._then);

  final ApplianceLocalState _self;
  final $Res Function(ApplianceLocalState) _then;

/// Create a copy of ApplianceLocalState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usageLevel = null,Object? count = null,Object? selectedDropdowns = null,Object? isExpanded = null,}) {
  return _then(_self.copyWith(
usageLevel: null == usageLevel ? _self.usageLevel : usageLevel // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,selectedDropdowns: null == selectedDropdowns ? _self.selectedDropdowns : selectedDropdowns // ignore: cast_nullable_to_non_nullable
as Map<String, String>,isExpanded: null == isExpanded ? _self.isExpanded : isExpanded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ApplianceLocalState].
extension ApplianceLocalStatePatterns on ApplianceLocalState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplianceLocalState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplianceLocalState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplianceLocalState value)  $default,){
final _that = this;
switch (_that) {
case _ApplianceLocalState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplianceLocalState value)?  $default,){
final _that = this;
switch (_that) {
case _ApplianceLocalState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String usageLevel,  int count,  Map<String, String> selectedDropdowns,  bool isExpanded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplianceLocalState() when $default != null:
return $default(_that.usageLevel,_that.count,_that.selectedDropdowns,_that.isExpanded);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String usageLevel,  int count,  Map<String, String> selectedDropdowns,  bool isExpanded)  $default,) {final _that = this;
switch (_that) {
case _ApplianceLocalState():
return $default(_that.usageLevel,_that.count,_that.selectedDropdowns,_that.isExpanded);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String usageLevel,  int count,  Map<String, String> selectedDropdowns,  bool isExpanded)?  $default,) {final _that = this;
switch (_that) {
case _ApplianceLocalState() when $default != null:
return $default(_that.usageLevel,_that.count,_that.selectedDropdowns,_that.isExpanded);case _:
  return null;

}
}

}

/// @nodoc


class _ApplianceLocalState implements ApplianceLocalState {
  const _ApplianceLocalState({required this.usageLevel, required this.count, required final  Map<String, String> selectedDropdowns, this.isExpanded = false}): _selectedDropdowns = selectedDropdowns;
  

@override final  String usageLevel;
@override final  int count;
 final  Map<String, String> _selectedDropdowns;
@override Map<String, String> get selectedDropdowns {
  if (_selectedDropdowns is EqualUnmodifiableMapView) return _selectedDropdowns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectedDropdowns);
}

@override@JsonKey() final  bool isExpanded;

/// Create a copy of ApplianceLocalState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplianceLocalStateCopyWith<_ApplianceLocalState> get copyWith => __$ApplianceLocalStateCopyWithImpl<_ApplianceLocalState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplianceLocalState&&(identical(other.usageLevel, usageLevel) || other.usageLevel == usageLevel)&&(identical(other.count, count) || other.count == count)&&const DeepCollectionEquality().equals(other._selectedDropdowns, _selectedDropdowns)&&(identical(other.isExpanded, isExpanded) || other.isExpanded == isExpanded));
}


@override
int get hashCode => Object.hash(runtimeType,usageLevel,count,const DeepCollectionEquality().hash(_selectedDropdowns),isExpanded);

@override
String toString() {
  return 'ApplianceLocalState(usageLevel: $usageLevel, count: $count, selectedDropdowns: $selectedDropdowns, isExpanded: $isExpanded)';
}


}

/// @nodoc
abstract mixin class _$ApplianceLocalStateCopyWith<$Res> implements $ApplianceLocalStateCopyWith<$Res> {
  factory _$ApplianceLocalStateCopyWith(_ApplianceLocalState value, $Res Function(_ApplianceLocalState) _then) = __$ApplianceLocalStateCopyWithImpl;
@override @useResult
$Res call({
 String usageLevel, int count, Map<String, String> selectedDropdowns, bool isExpanded
});




}
/// @nodoc
class __$ApplianceLocalStateCopyWithImpl<$Res>
    implements _$ApplianceLocalStateCopyWith<$Res> {
  __$ApplianceLocalStateCopyWithImpl(this._self, this._then);

  final _ApplianceLocalState _self;
  final $Res Function(_ApplianceLocalState) _then;

/// Create a copy of ApplianceLocalState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usageLevel = null,Object? count = null,Object? selectedDropdowns = null,Object? isExpanded = null,}) {
  return _then(_ApplianceLocalState(
usageLevel: null == usageLevel ? _self.usageLevel : usageLevel // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,selectedDropdowns: null == selectedDropdowns ? _self._selectedDropdowns : selectedDropdowns // ignore: cast_nullable_to_non_nullable
as Map<String, String>,isExpanded: null == isExpanded ? _self.isExpanded : isExpanded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$OnBoardingPage5State {

 Map<String, ApplianceLocalState> get localStates;
/// Create a copy of OnBoardingPage5State
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnBoardingPage5StateCopyWith<OnBoardingPage5State> get copyWith => _$OnBoardingPage5StateCopyWithImpl<OnBoardingPage5State>(this as OnBoardingPage5State, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnBoardingPage5State&&const DeepCollectionEquality().equals(other.localStates, localStates));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(localStates));

@override
String toString() {
  return 'OnBoardingPage5State(localStates: $localStates)';
}


}

/// @nodoc
abstract mixin class $OnBoardingPage5StateCopyWith<$Res>  {
  factory $OnBoardingPage5StateCopyWith(OnBoardingPage5State value, $Res Function(OnBoardingPage5State) _then) = _$OnBoardingPage5StateCopyWithImpl;
@useResult
$Res call({
 Map<String, ApplianceLocalState> localStates
});




}
/// @nodoc
class _$OnBoardingPage5StateCopyWithImpl<$Res>
    implements $OnBoardingPage5StateCopyWith<$Res> {
  _$OnBoardingPage5StateCopyWithImpl(this._self, this._then);

  final OnBoardingPage5State _self;
  final $Res Function(OnBoardingPage5State) _then;

/// Create a copy of OnBoardingPage5State
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localStates = null,}) {
  return _then(_self.copyWith(
localStates: null == localStates ? _self.localStates : localStates // ignore: cast_nullable_to_non_nullable
as Map<String, ApplianceLocalState>,
  ));
}

}


/// Adds pattern-matching-related methods to [OnBoardingPage5State].
extension OnBoardingPage5StatePatterns on OnBoardingPage5State {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnBoardingPage5State value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnBoardingPage5State() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnBoardingPage5State value)  $default,){
final _that = this;
switch (_that) {
case _OnBoardingPage5State():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnBoardingPage5State value)?  $default,){
final _that = this;
switch (_that) {
case _OnBoardingPage5State() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, ApplianceLocalState> localStates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnBoardingPage5State() when $default != null:
return $default(_that.localStates);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, ApplianceLocalState> localStates)  $default,) {final _that = this;
switch (_that) {
case _OnBoardingPage5State():
return $default(_that.localStates);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, ApplianceLocalState> localStates)?  $default,) {final _that = this;
switch (_that) {
case _OnBoardingPage5State() when $default != null:
return $default(_that.localStates);case _:
  return null;

}
}

}

/// @nodoc


class _OnBoardingPage5State implements OnBoardingPage5State {
  const _OnBoardingPage5State({final  Map<String, ApplianceLocalState> localStates = const {}}): _localStates = localStates;
  

 final  Map<String, ApplianceLocalState> _localStates;
@override@JsonKey() Map<String, ApplianceLocalState> get localStates {
  if (_localStates is EqualUnmodifiableMapView) return _localStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_localStates);
}


/// Create a copy of OnBoardingPage5State
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnBoardingPage5StateCopyWith<_OnBoardingPage5State> get copyWith => __$OnBoardingPage5StateCopyWithImpl<_OnBoardingPage5State>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnBoardingPage5State&&const DeepCollectionEquality().equals(other._localStates, _localStates));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_localStates));

@override
String toString() {
  return 'OnBoardingPage5State(localStates: $localStates)';
}


}

/// @nodoc
abstract mixin class _$OnBoardingPage5StateCopyWith<$Res> implements $OnBoardingPage5StateCopyWith<$Res> {
  factory _$OnBoardingPage5StateCopyWith(_OnBoardingPage5State value, $Res Function(_OnBoardingPage5State) _then) = __$OnBoardingPage5StateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, ApplianceLocalState> localStates
});




}
/// @nodoc
class __$OnBoardingPage5StateCopyWithImpl<$Res>
    implements _$OnBoardingPage5StateCopyWith<$Res> {
  __$OnBoardingPage5StateCopyWithImpl(this._self, this._then);

  final _OnBoardingPage5State _self;
  final $Res Function(_OnBoardingPage5State) _then;

/// Create a copy of OnBoardingPage5State
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localStates = null,}) {
  return _then(_OnBoardingPage5State(
localStates: null == localStates ? _self._localStates : localStates // ignore: cast_nullable_to_non_nullable
as Map<String, ApplianceLocalState>,
  ));
}


}

// dart format on
