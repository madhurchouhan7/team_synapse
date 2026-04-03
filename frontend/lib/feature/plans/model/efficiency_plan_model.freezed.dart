// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'efficiency_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EfficiencyPlanModel {

 String get summary; double get estimatedCurrentMonthlyCost; EstimatedSavings get estimatedSavingsIfFollowed; double get efficiencyScore; List<KeyAction> get keyActions; SlabAlert get slabAlert; List<String> get quickWins; String get monthlyTip;
/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EfficiencyPlanModelCopyWith<EfficiencyPlanModel> get copyWith => _$EfficiencyPlanModelCopyWithImpl<EfficiencyPlanModel>(this as EfficiencyPlanModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EfficiencyPlanModel&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.estimatedCurrentMonthlyCost, estimatedCurrentMonthlyCost) || other.estimatedCurrentMonthlyCost == estimatedCurrentMonthlyCost)&&(identical(other.estimatedSavingsIfFollowed, estimatedSavingsIfFollowed) || other.estimatedSavingsIfFollowed == estimatedSavingsIfFollowed)&&(identical(other.efficiencyScore, efficiencyScore) || other.efficiencyScore == efficiencyScore)&&const DeepCollectionEquality().equals(other.keyActions, keyActions)&&(identical(other.slabAlert, slabAlert) || other.slabAlert == slabAlert)&&const DeepCollectionEquality().equals(other.quickWins, quickWins)&&(identical(other.monthlyTip, monthlyTip) || other.monthlyTip == monthlyTip));
}


@override
int get hashCode => Object.hash(runtimeType,summary,estimatedCurrentMonthlyCost,estimatedSavingsIfFollowed,efficiencyScore,const DeepCollectionEquality().hash(keyActions),slabAlert,const DeepCollectionEquality().hash(quickWins),monthlyTip);

@override
String toString() {
  return 'EfficiencyPlanModel(summary: $summary, estimatedCurrentMonthlyCost: $estimatedCurrentMonthlyCost, estimatedSavingsIfFollowed: $estimatedSavingsIfFollowed, efficiencyScore: $efficiencyScore, keyActions: $keyActions, slabAlert: $slabAlert, quickWins: $quickWins, monthlyTip: $monthlyTip)';
}


}

/// @nodoc
abstract mixin class $EfficiencyPlanModelCopyWith<$Res>  {
  factory $EfficiencyPlanModelCopyWith(EfficiencyPlanModel value, $Res Function(EfficiencyPlanModel) _then) = _$EfficiencyPlanModelCopyWithImpl;
@useResult
$Res call({
 String summary, double estimatedCurrentMonthlyCost, EstimatedSavings estimatedSavingsIfFollowed, double efficiencyScore, List<KeyAction> keyActions, SlabAlert slabAlert, List<String> quickWins, String monthlyTip
});


$EstimatedSavingsCopyWith<$Res> get estimatedSavingsIfFollowed;$SlabAlertCopyWith<$Res> get slabAlert;

}
/// @nodoc
class _$EfficiencyPlanModelCopyWithImpl<$Res>
    implements $EfficiencyPlanModelCopyWith<$Res> {
  _$EfficiencyPlanModelCopyWithImpl(this._self, this._then);

  final EfficiencyPlanModel _self;
  final $Res Function(EfficiencyPlanModel) _then;

/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? estimatedCurrentMonthlyCost = null,Object? estimatedSavingsIfFollowed = null,Object? efficiencyScore = null,Object? keyActions = null,Object? slabAlert = null,Object? quickWins = null,Object? monthlyTip = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,estimatedCurrentMonthlyCost: null == estimatedCurrentMonthlyCost ? _self.estimatedCurrentMonthlyCost : estimatedCurrentMonthlyCost // ignore: cast_nullable_to_non_nullable
as double,estimatedSavingsIfFollowed: null == estimatedSavingsIfFollowed ? _self.estimatedSavingsIfFollowed : estimatedSavingsIfFollowed // ignore: cast_nullable_to_non_nullable
as EstimatedSavings,efficiencyScore: null == efficiencyScore ? _self.efficiencyScore : efficiencyScore // ignore: cast_nullable_to_non_nullable
as double,keyActions: null == keyActions ? _self.keyActions : keyActions // ignore: cast_nullable_to_non_nullable
as List<KeyAction>,slabAlert: null == slabAlert ? _self.slabAlert : slabAlert // ignore: cast_nullable_to_non_nullable
as SlabAlert,quickWins: null == quickWins ? _self.quickWins : quickWins // ignore: cast_nullable_to_non_nullable
as List<String>,monthlyTip: null == monthlyTip ? _self.monthlyTip : monthlyTip // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EstimatedSavingsCopyWith<$Res> get estimatedSavingsIfFollowed {
  
  return $EstimatedSavingsCopyWith<$Res>(_self.estimatedSavingsIfFollowed, (value) {
    return _then(_self.copyWith(estimatedSavingsIfFollowed: value));
  });
}/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlabAlertCopyWith<$Res> get slabAlert {
  
  return $SlabAlertCopyWith<$Res>(_self.slabAlert, (value) {
    return _then(_self.copyWith(slabAlert: value));
  });
}
}


/// Adds pattern-matching-related methods to [EfficiencyPlanModel].
extension EfficiencyPlanModelPatterns on EfficiencyPlanModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EfficiencyPlanModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EfficiencyPlanModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EfficiencyPlanModel value)  $default,){
final _that = this;
switch (_that) {
case _EfficiencyPlanModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EfficiencyPlanModel value)?  $default,){
final _that = this;
switch (_that) {
case _EfficiencyPlanModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String summary,  double estimatedCurrentMonthlyCost,  EstimatedSavings estimatedSavingsIfFollowed,  double efficiencyScore,  List<KeyAction> keyActions,  SlabAlert slabAlert,  List<String> quickWins,  String monthlyTip)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EfficiencyPlanModel() when $default != null:
return $default(_that.summary,_that.estimatedCurrentMonthlyCost,_that.estimatedSavingsIfFollowed,_that.efficiencyScore,_that.keyActions,_that.slabAlert,_that.quickWins,_that.monthlyTip);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String summary,  double estimatedCurrentMonthlyCost,  EstimatedSavings estimatedSavingsIfFollowed,  double efficiencyScore,  List<KeyAction> keyActions,  SlabAlert slabAlert,  List<String> quickWins,  String monthlyTip)  $default,) {final _that = this;
switch (_that) {
case _EfficiencyPlanModel():
return $default(_that.summary,_that.estimatedCurrentMonthlyCost,_that.estimatedSavingsIfFollowed,_that.efficiencyScore,_that.keyActions,_that.slabAlert,_that.quickWins,_that.monthlyTip);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String summary,  double estimatedCurrentMonthlyCost,  EstimatedSavings estimatedSavingsIfFollowed,  double efficiencyScore,  List<KeyAction> keyActions,  SlabAlert slabAlert,  List<String> quickWins,  String monthlyTip)?  $default,) {final _that = this;
switch (_that) {
case _EfficiencyPlanModel() when $default != null:
return $default(_that.summary,_that.estimatedCurrentMonthlyCost,_that.estimatedSavingsIfFollowed,_that.efficiencyScore,_that.keyActions,_that.slabAlert,_that.quickWins,_that.monthlyTip);case _:
  return null;

}
}

}

/// @nodoc


class _EfficiencyPlanModel implements EfficiencyPlanModel {
  const _EfficiencyPlanModel({required this.summary, required this.estimatedCurrentMonthlyCost, required this.estimatedSavingsIfFollowed, required this.efficiencyScore, required final  List<KeyAction> keyActions, required this.slabAlert, required final  List<String> quickWins, required this.monthlyTip}): _keyActions = keyActions,_quickWins = quickWins;
  

@override final  String summary;
@override final  double estimatedCurrentMonthlyCost;
@override final  EstimatedSavings estimatedSavingsIfFollowed;
@override final  double efficiencyScore;
 final  List<KeyAction> _keyActions;
@override List<KeyAction> get keyActions {
  if (_keyActions is EqualUnmodifiableListView) return _keyActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_keyActions);
}

@override final  SlabAlert slabAlert;
 final  List<String> _quickWins;
@override List<String> get quickWins {
  if (_quickWins is EqualUnmodifiableListView) return _quickWins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quickWins);
}

@override final  String monthlyTip;

/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EfficiencyPlanModelCopyWith<_EfficiencyPlanModel> get copyWith => __$EfficiencyPlanModelCopyWithImpl<_EfficiencyPlanModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EfficiencyPlanModel&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.estimatedCurrentMonthlyCost, estimatedCurrentMonthlyCost) || other.estimatedCurrentMonthlyCost == estimatedCurrentMonthlyCost)&&(identical(other.estimatedSavingsIfFollowed, estimatedSavingsIfFollowed) || other.estimatedSavingsIfFollowed == estimatedSavingsIfFollowed)&&(identical(other.efficiencyScore, efficiencyScore) || other.efficiencyScore == efficiencyScore)&&const DeepCollectionEquality().equals(other._keyActions, _keyActions)&&(identical(other.slabAlert, slabAlert) || other.slabAlert == slabAlert)&&const DeepCollectionEquality().equals(other._quickWins, _quickWins)&&(identical(other.monthlyTip, monthlyTip) || other.monthlyTip == monthlyTip));
}


@override
int get hashCode => Object.hash(runtimeType,summary,estimatedCurrentMonthlyCost,estimatedSavingsIfFollowed,efficiencyScore,const DeepCollectionEquality().hash(_keyActions),slabAlert,const DeepCollectionEquality().hash(_quickWins),monthlyTip);

@override
String toString() {
  return 'EfficiencyPlanModel(summary: $summary, estimatedCurrentMonthlyCost: $estimatedCurrentMonthlyCost, estimatedSavingsIfFollowed: $estimatedSavingsIfFollowed, efficiencyScore: $efficiencyScore, keyActions: $keyActions, slabAlert: $slabAlert, quickWins: $quickWins, monthlyTip: $monthlyTip)';
}


}

/// @nodoc
abstract mixin class _$EfficiencyPlanModelCopyWith<$Res> implements $EfficiencyPlanModelCopyWith<$Res> {
  factory _$EfficiencyPlanModelCopyWith(_EfficiencyPlanModel value, $Res Function(_EfficiencyPlanModel) _then) = __$EfficiencyPlanModelCopyWithImpl;
@override @useResult
$Res call({
 String summary, double estimatedCurrentMonthlyCost, EstimatedSavings estimatedSavingsIfFollowed, double efficiencyScore, List<KeyAction> keyActions, SlabAlert slabAlert, List<String> quickWins, String monthlyTip
});


@override $EstimatedSavingsCopyWith<$Res> get estimatedSavingsIfFollowed;@override $SlabAlertCopyWith<$Res> get slabAlert;

}
/// @nodoc
class __$EfficiencyPlanModelCopyWithImpl<$Res>
    implements _$EfficiencyPlanModelCopyWith<$Res> {
  __$EfficiencyPlanModelCopyWithImpl(this._self, this._then);

  final _EfficiencyPlanModel _self;
  final $Res Function(_EfficiencyPlanModel) _then;

/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? estimatedCurrentMonthlyCost = null,Object? estimatedSavingsIfFollowed = null,Object? efficiencyScore = null,Object? keyActions = null,Object? slabAlert = null,Object? quickWins = null,Object? monthlyTip = null,}) {
  return _then(_EfficiencyPlanModel(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,estimatedCurrentMonthlyCost: null == estimatedCurrentMonthlyCost ? _self.estimatedCurrentMonthlyCost : estimatedCurrentMonthlyCost // ignore: cast_nullable_to_non_nullable
as double,estimatedSavingsIfFollowed: null == estimatedSavingsIfFollowed ? _self.estimatedSavingsIfFollowed : estimatedSavingsIfFollowed // ignore: cast_nullable_to_non_nullable
as EstimatedSavings,efficiencyScore: null == efficiencyScore ? _self.efficiencyScore : efficiencyScore // ignore: cast_nullable_to_non_nullable
as double,keyActions: null == keyActions ? _self._keyActions : keyActions // ignore: cast_nullable_to_non_nullable
as List<KeyAction>,slabAlert: null == slabAlert ? _self.slabAlert : slabAlert // ignore: cast_nullable_to_non_nullable
as SlabAlert,quickWins: null == quickWins ? _self._quickWins : quickWins // ignore: cast_nullable_to_non_nullable
as List<String>,monthlyTip: null == monthlyTip ? _self.monthlyTip : monthlyTip // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EstimatedSavingsCopyWith<$Res> get estimatedSavingsIfFollowed {
  
  return $EstimatedSavingsCopyWith<$Res>(_self.estimatedSavingsIfFollowed, (value) {
    return _then(_self.copyWith(estimatedSavingsIfFollowed: value));
  });
}/// Create a copy of EfficiencyPlanModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SlabAlertCopyWith<$Res> get slabAlert {
  
  return $SlabAlertCopyWith<$Res>(_self.slabAlert, (value) {
    return _then(_self.copyWith(slabAlert: value));
  });
}
}

/// @nodoc
mixin _$EstimatedSavings {

 double get units; double get rupees; double get percentage;
/// Create a copy of EstimatedSavings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EstimatedSavingsCopyWith<EstimatedSavings> get copyWith => _$EstimatedSavingsCopyWithImpl<EstimatedSavings>(this as EstimatedSavings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EstimatedSavings&&(identical(other.units, units) || other.units == units)&&(identical(other.rupees, rupees) || other.rupees == rupees)&&(identical(other.percentage, percentage) || other.percentage == percentage));
}


@override
int get hashCode => Object.hash(runtimeType,units,rupees,percentage);

@override
String toString() {
  return 'EstimatedSavings(units: $units, rupees: $rupees, percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class $EstimatedSavingsCopyWith<$Res>  {
  factory $EstimatedSavingsCopyWith(EstimatedSavings value, $Res Function(EstimatedSavings) _then) = _$EstimatedSavingsCopyWithImpl;
@useResult
$Res call({
 double units, double rupees, double percentage
});




}
/// @nodoc
class _$EstimatedSavingsCopyWithImpl<$Res>
    implements $EstimatedSavingsCopyWith<$Res> {
  _$EstimatedSavingsCopyWithImpl(this._self, this._then);

  final EstimatedSavings _self;
  final $Res Function(EstimatedSavings) _then;

/// Create a copy of EstimatedSavings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? units = null,Object? rupees = null,Object? percentage = null,}) {
  return _then(_self.copyWith(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as double,rupees: null == rupees ? _self.rupees : rupees // ignore: cast_nullable_to_non_nullable
as double,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [EstimatedSavings].
extension EstimatedSavingsPatterns on EstimatedSavings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EstimatedSavings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EstimatedSavings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EstimatedSavings value)  $default,){
final _that = this;
switch (_that) {
case _EstimatedSavings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EstimatedSavings value)?  $default,){
final _that = this;
switch (_that) {
case _EstimatedSavings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double units,  double rupees,  double percentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EstimatedSavings() when $default != null:
return $default(_that.units,_that.rupees,_that.percentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double units,  double rupees,  double percentage)  $default,) {final _that = this;
switch (_that) {
case _EstimatedSavings():
return $default(_that.units,_that.rupees,_that.percentage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double units,  double rupees,  double percentage)?  $default,) {final _that = this;
switch (_that) {
case _EstimatedSavings() when $default != null:
return $default(_that.units,_that.rupees,_that.percentage);case _:
  return null;

}
}

}

/// @nodoc


class _EstimatedSavings implements EstimatedSavings {
  const _EstimatedSavings({required this.units, required this.rupees, required this.percentage});
  

@override final  double units;
@override final  double rupees;
@override final  double percentage;

/// Create a copy of EstimatedSavings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EstimatedSavingsCopyWith<_EstimatedSavings> get copyWith => __$EstimatedSavingsCopyWithImpl<_EstimatedSavings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EstimatedSavings&&(identical(other.units, units) || other.units == units)&&(identical(other.rupees, rupees) || other.rupees == rupees)&&(identical(other.percentage, percentage) || other.percentage == percentage));
}


@override
int get hashCode => Object.hash(runtimeType,units,rupees,percentage);

@override
String toString() {
  return 'EstimatedSavings(units: $units, rupees: $rupees, percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class _$EstimatedSavingsCopyWith<$Res> implements $EstimatedSavingsCopyWith<$Res> {
  factory _$EstimatedSavingsCopyWith(_EstimatedSavings value, $Res Function(_EstimatedSavings) _then) = __$EstimatedSavingsCopyWithImpl;
@override @useResult
$Res call({
 double units, double rupees, double percentage
});




}
/// @nodoc
class __$EstimatedSavingsCopyWithImpl<$Res>
    implements _$EstimatedSavingsCopyWith<$Res> {
  __$EstimatedSavingsCopyWithImpl(this._self, this._then);

  final _EstimatedSavings _self;
  final $Res Function(_EstimatedSavings) _then;

/// Create a copy of EstimatedSavings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? units = null,Object? rupees = null,Object? percentage = null,}) {
  return _then(_EstimatedSavings(
units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as double,rupees: null == rupees ? _self.rupees : rupees // ignore: cast_nullable_to_non_nullable
as double,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$KeyAction {

 String get priority; String get appliance; String get action; String get impact; String get estimatedSaving;
/// Create a copy of KeyAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KeyActionCopyWith<KeyAction> get copyWith => _$KeyActionCopyWithImpl<KeyAction>(this as KeyAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KeyAction&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.appliance, appliance) || other.appliance == appliance)&&(identical(other.action, action) || other.action == action)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.estimatedSaving, estimatedSaving) || other.estimatedSaving == estimatedSaving));
}


@override
int get hashCode => Object.hash(runtimeType,priority,appliance,action,impact,estimatedSaving);

@override
String toString() {
  return 'KeyAction(priority: $priority, appliance: $appliance, action: $action, impact: $impact, estimatedSaving: $estimatedSaving)';
}


}

/// @nodoc
abstract mixin class $KeyActionCopyWith<$Res>  {
  factory $KeyActionCopyWith(KeyAction value, $Res Function(KeyAction) _then) = _$KeyActionCopyWithImpl;
@useResult
$Res call({
 String priority, String appliance, String action, String impact, String estimatedSaving
});




}
/// @nodoc
class _$KeyActionCopyWithImpl<$Res>
    implements $KeyActionCopyWith<$Res> {
  _$KeyActionCopyWithImpl(this._self, this._then);

  final KeyAction _self;
  final $Res Function(KeyAction) _then;

/// Create a copy of KeyAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? priority = null,Object? appliance = null,Object? action = null,Object? impact = null,Object? estimatedSaving = null,}) {
  return _then(_self.copyWith(
priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,appliance: null == appliance ? _self.appliance : appliance // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String,estimatedSaving: null == estimatedSaving ? _self.estimatedSaving : estimatedSaving // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [KeyAction].
extension KeyActionPatterns on KeyAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KeyAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KeyAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KeyAction value)  $default,){
final _that = this;
switch (_that) {
case _KeyAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KeyAction value)?  $default,){
final _that = this;
switch (_that) {
case _KeyAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String priority,  String appliance,  String action,  String impact,  String estimatedSaving)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KeyAction() when $default != null:
return $default(_that.priority,_that.appliance,_that.action,_that.impact,_that.estimatedSaving);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String priority,  String appliance,  String action,  String impact,  String estimatedSaving)  $default,) {final _that = this;
switch (_that) {
case _KeyAction():
return $default(_that.priority,_that.appliance,_that.action,_that.impact,_that.estimatedSaving);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String priority,  String appliance,  String action,  String impact,  String estimatedSaving)?  $default,) {final _that = this;
switch (_that) {
case _KeyAction() when $default != null:
return $default(_that.priority,_that.appliance,_that.action,_that.impact,_that.estimatedSaving);case _:
  return null;

}
}

}

/// @nodoc


class _KeyAction implements KeyAction {
  const _KeyAction({required this.priority, required this.appliance, required this.action, required this.impact, required this.estimatedSaving});
  

@override final  String priority;
@override final  String appliance;
@override final  String action;
@override final  String impact;
@override final  String estimatedSaving;

/// Create a copy of KeyAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KeyActionCopyWith<_KeyAction> get copyWith => __$KeyActionCopyWithImpl<_KeyAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KeyAction&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.appliance, appliance) || other.appliance == appliance)&&(identical(other.action, action) || other.action == action)&&(identical(other.impact, impact) || other.impact == impact)&&(identical(other.estimatedSaving, estimatedSaving) || other.estimatedSaving == estimatedSaving));
}


@override
int get hashCode => Object.hash(runtimeType,priority,appliance,action,impact,estimatedSaving);

@override
String toString() {
  return 'KeyAction(priority: $priority, appliance: $appliance, action: $action, impact: $impact, estimatedSaving: $estimatedSaving)';
}


}

/// @nodoc
abstract mixin class _$KeyActionCopyWith<$Res> implements $KeyActionCopyWith<$Res> {
  factory _$KeyActionCopyWith(_KeyAction value, $Res Function(_KeyAction) _then) = __$KeyActionCopyWithImpl;
@override @useResult
$Res call({
 String priority, String appliance, String action, String impact, String estimatedSaving
});




}
/// @nodoc
class __$KeyActionCopyWithImpl<$Res>
    implements _$KeyActionCopyWith<$Res> {
  __$KeyActionCopyWithImpl(this._self, this._then);

  final _KeyAction _self;
  final $Res Function(_KeyAction) _then;

/// Create a copy of KeyAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? priority = null,Object? appliance = null,Object? action = null,Object? impact = null,Object? estimatedSaving = null,}) {
  return _then(_KeyAction(
priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,appliance: null == appliance ? _self.appliance : appliance // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,impact: null == impact ? _self.impact : impact // ignore: cast_nullable_to_non_nullable
as String,estimatedSaving: null == estimatedSaving ? _self.estimatedSaving : estimatedSaving // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SlabAlert {

 bool get isInDangerZone; String get currentSlab; double? get nextSlabAt; double? get unitsToNextSlab; String? get warning;
/// Create a copy of SlabAlert
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlabAlertCopyWith<SlabAlert> get copyWith => _$SlabAlertCopyWithImpl<SlabAlert>(this as SlabAlert, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlabAlert&&(identical(other.isInDangerZone, isInDangerZone) || other.isInDangerZone == isInDangerZone)&&(identical(other.currentSlab, currentSlab) || other.currentSlab == currentSlab)&&(identical(other.nextSlabAt, nextSlabAt) || other.nextSlabAt == nextSlabAt)&&(identical(other.unitsToNextSlab, unitsToNextSlab) || other.unitsToNextSlab == unitsToNextSlab)&&(identical(other.warning, warning) || other.warning == warning));
}


@override
int get hashCode => Object.hash(runtimeType,isInDangerZone,currentSlab,nextSlabAt,unitsToNextSlab,warning);

@override
String toString() {
  return 'SlabAlert(isInDangerZone: $isInDangerZone, currentSlab: $currentSlab, nextSlabAt: $nextSlabAt, unitsToNextSlab: $unitsToNextSlab, warning: $warning)';
}


}

/// @nodoc
abstract mixin class $SlabAlertCopyWith<$Res>  {
  factory $SlabAlertCopyWith(SlabAlert value, $Res Function(SlabAlert) _then) = _$SlabAlertCopyWithImpl;
@useResult
$Res call({
 bool isInDangerZone, String currentSlab, double? nextSlabAt, double? unitsToNextSlab, String? warning
});




}
/// @nodoc
class _$SlabAlertCopyWithImpl<$Res>
    implements $SlabAlertCopyWith<$Res> {
  _$SlabAlertCopyWithImpl(this._self, this._then);

  final SlabAlert _self;
  final $Res Function(SlabAlert) _then;

/// Create a copy of SlabAlert
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isInDangerZone = null,Object? currentSlab = null,Object? nextSlabAt = freezed,Object? unitsToNextSlab = freezed,Object? warning = freezed,}) {
  return _then(_self.copyWith(
isInDangerZone: null == isInDangerZone ? _self.isInDangerZone : isInDangerZone // ignore: cast_nullable_to_non_nullable
as bool,currentSlab: null == currentSlab ? _self.currentSlab : currentSlab // ignore: cast_nullable_to_non_nullable
as String,nextSlabAt: freezed == nextSlabAt ? _self.nextSlabAt : nextSlabAt // ignore: cast_nullable_to_non_nullable
as double?,unitsToNextSlab: freezed == unitsToNextSlab ? _self.unitsToNextSlab : unitsToNextSlab // ignore: cast_nullable_to_non_nullable
as double?,warning: freezed == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SlabAlert].
extension SlabAlertPatterns on SlabAlert {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlabAlert value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlabAlert() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlabAlert value)  $default,){
final _that = this;
switch (_that) {
case _SlabAlert():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlabAlert value)?  $default,){
final _that = this;
switch (_that) {
case _SlabAlert() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isInDangerZone,  String currentSlab,  double? nextSlabAt,  double? unitsToNextSlab,  String? warning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlabAlert() when $default != null:
return $default(_that.isInDangerZone,_that.currentSlab,_that.nextSlabAt,_that.unitsToNextSlab,_that.warning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isInDangerZone,  String currentSlab,  double? nextSlabAt,  double? unitsToNextSlab,  String? warning)  $default,) {final _that = this;
switch (_that) {
case _SlabAlert():
return $default(_that.isInDangerZone,_that.currentSlab,_that.nextSlabAt,_that.unitsToNextSlab,_that.warning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isInDangerZone,  String currentSlab,  double? nextSlabAt,  double? unitsToNextSlab,  String? warning)?  $default,) {final _that = this;
switch (_that) {
case _SlabAlert() when $default != null:
return $default(_that.isInDangerZone,_that.currentSlab,_that.nextSlabAt,_that.unitsToNextSlab,_that.warning);case _:
  return null;

}
}

}

/// @nodoc


class _SlabAlert implements SlabAlert {
  const _SlabAlert({required this.isInDangerZone, required this.currentSlab, this.nextSlabAt, this.unitsToNextSlab, this.warning});
  

@override final  bool isInDangerZone;
@override final  String currentSlab;
@override final  double? nextSlabAt;
@override final  double? unitsToNextSlab;
@override final  String? warning;

/// Create a copy of SlabAlert
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlabAlertCopyWith<_SlabAlert> get copyWith => __$SlabAlertCopyWithImpl<_SlabAlert>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlabAlert&&(identical(other.isInDangerZone, isInDangerZone) || other.isInDangerZone == isInDangerZone)&&(identical(other.currentSlab, currentSlab) || other.currentSlab == currentSlab)&&(identical(other.nextSlabAt, nextSlabAt) || other.nextSlabAt == nextSlabAt)&&(identical(other.unitsToNextSlab, unitsToNextSlab) || other.unitsToNextSlab == unitsToNextSlab)&&(identical(other.warning, warning) || other.warning == warning));
}


@override
int get hashCode => Object.hash(runtimeType,isInDangerZone,currentSlab,nextSlabAt,unitsToNextSlab,warning);

@override
String toString() {
  return 'SlabAlert(isInDangerZone: $isInDangerZone, currentSlab: $currentSlab, nextSlabAt: $nextSlabAt, unitsToNextSlab: $unitsToNextSlab, warning: $warning)';
}


}

/// @nodoc
abstract mixin class _$SlabAlertCopyWith<$Res> implements $SlabAlertCopyWith<$Res> {
  factory _$SlabAlertCopyWith(_SlabAlert value, $Res Function(_SlabAlert) _then) = __$SlabAlertCopyWithImpl;
@override @useResult
$Res call({
 bool isInDangerZone, String currentSlab, double? nextSlabAt, double? unitsToNextSlab, String? warning
});




}
/// @nodoc
class __$SlabAlertCopyWithImpl<$Res>
    implements _$SlabAlertCopyWith<$Res> {
  __$SlabAlertCopyWithImpl(this._self, this._then);

  final _SlabAlert _self;
  final $Res Function(_SlabAlert) _then;

/// Create a copy of SlabAlert
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isInDangerZone = null,Object? currentSlab = null,Object? nextSlabAt = freezed,Object? unitsToNextSlab = freezed,Object? warning = freezed,}) {
  return _then(_SlabAlert(
isInDangerZone: null == isInDangerZone ? _self.isInDangerZone : isInDangerZone // ignore: cast_nullable_to_non_nullable
as bool,currentSlab: null == currentSlab ? _self.currentSlab : currentSlab // ignore: cast_nullable_to_non_nullable
as String,nextSlabAt: freezed == nextSlabAt ? _self.nextSlabAt : nextSlabAt // ignore: cast_nullable_to_non_nullable
as double?,unitsToNextSlab: freezed == unitsToNextSlab ? _self.unitsToNextSlab : unitsToNextSlab // ignore: cast_nullable_to_non_nullable
as double?,warning: freezed == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
