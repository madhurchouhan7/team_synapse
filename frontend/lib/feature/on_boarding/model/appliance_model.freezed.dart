// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'appliance_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApplianceModel {

 String get id; String get title; String get description; String get svgPath; String get category; double get usageHours;
/// Create a copy of ApplianceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplianceModelCopyWith<ApplianceModel> get copyWith => _$ApplianceModelCopyWithImpl<ApplianceModel>(this as ApplianceModel, _$identity);

  /// Serializes this ApplianceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplianceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&(identical(other.category, category) || other.category == category)&&(identical(other.usageHours, usageHours) || other.usageHours == usageHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,svgPath,category,usageHours);

@override
String toString() {
  return 'ApplianceModel(id: $id, title: $title, description: $description, svgPath: $svgPath, category: $category, usageHours: $usageHours)';
}


}

/// @nodoc
abstract mixin class $ApplianceModelCopyWith<$Res>  {
  factory $ApplianceModelCopyWith(ApplianceModel value, $Res Function(ApplianceModel) _then) = _$ApplianceModelCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, String svgPath, String category, double usageHours
});




}
/// @nodoc
class _$ApplianceModelCopyWithImpl<$Res>
    implements $ApplianceModelCopyWith<$Res> {
  _$ApplianceModelCopyWithImpl(this._self, this._then);

  final ApplianceModel _self;
  final $Res Function(ApplianceModel) _then;

/// Create a copy of ApplianceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? svgPath = null,Object? category = null,Object? usageHours = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,svgPath: null == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,usageHours: null == usageHours ? _self.usageHours : usageHours // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ApplianceModel].
extension ApplianceModelPatterns on ApplianceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplianceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplianceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplianceModel value)  $default,){
final _that = this;
switch (_that) {
case _ApplianceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplianceModel value)?  $default,){
final _that = this;
switch (_that) {
case _ApplianceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String svgPath,  String category,  double usageHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplianceModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.svgPath,_that.category,_that.usageHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  String svgPath,  String category,  double usageHours)  $default,) {final _that = this;
switch (_that) {
case _ApplianceModel():
return $default(_that.id,_that.title,_that.description,_that.svgPath,_that.category,_that.usageHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  String svgPath,  String category,  double usageHours)?  $default,) {final _that = this;
switch (_that) {
case _ApplianceModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.svgPath,_that.category,_that.usageHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApplianceModel implements ApplianceModel {
  const _ApplianceModel({required this.id, required this.title, required this.description, required this.svgPath, required this.category, this.usageHours = 2.0});
  factory _ApplianceModel.fromJson(Map<String, dynamic> json) => _$ApplianceModelFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  String svgPath;
@override final  String category;
@override@JsonKey() final  double usageHours;

/// Create a copy of ApplianceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplianceModelCopyWith<_ApplianceModel> get copyWith => __$ApplianceModelCopyWithImpl<_ApplianceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApplianceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplianceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.svgPath, svgPath) || other.svgPath == svgPath)&&(identical(other.category, category) || other.category == category)&&(identical(other.usageHours, usageHours) || other.usageHours == usageHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,svgPath,category,usageHours);

@override
String toString() {
  return 'ApplianceModel(id: $id, title: $title, description: $description, svgPath: $svgPath, category: $category, usageHours: $usageHours)';
}


}

/// @nodoc
abstract mixin class _$ApplianceModelCopyWith<$Res> implements $ApplianceModelCopyWith<$Res> {
  factory _$ApplianceModelCopyWith(_ApplianceModel value, $Res Function(_ApplianceModel) _then) = __$ApplianceModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, String svgPath, String category, double usageHours
});




}
/// @nodoc
class __$ApplianceModelCopyWithImpl<$Res>
    implements _$ApplianceModelCopyWith<$Res> {
  __$ApplianceModelCopyWithImpl(this._self, this._then);

  final _ApplianceModel _self;
  final $Res Function(_ApplianceModel) _then;

/// Create a copy of ApplianceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? svgPath = null,Object? category = null,Object? usageHours = null,}) {
  return _then(_ApplianceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,svgPath: null == svgPath ? _self.svgPath : svgPath // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,usageHours: null == usageHours ? _self.usageHours : usageHours // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
