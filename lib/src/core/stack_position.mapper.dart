// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'stack_position.dart';

class StackPositionDataMapper extends ClassMapperBase<StackPositionData> {
  StackPositionDataMapper._();

  static StackPositionDataMapper? _instance;
  static StackPositionDataMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = StackPositionDataMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'StackPositionData';

  static String _$id(StackPositionData v) => v.id;
  static const Field<StackPositionData, String> _f$id = Field('id', _$id);
  static int _$layer(StackPositionData v) => v.layer;
  static const Field<StackPositionData, int> _f$layer = Field('layer', _$layer);
  static Offset _$offset(StackPositionData v) => v.offset;
  static const Field<StackPositionData, Offset> _f$offset =
      Field('offset', _$offset);
  static bool _$keepAlive(StackPositionData v) => v.keepAlive;
  static const Field<StackPositionData, bool> _f$keepAlive =
      Field('keepAlive', _$keepAlive, opt: true, def: false);
  static double? _$width(StackPositionData v) => v.width;
  static const Field<StackPositionData, double> _f$width =
      Field('width', _$width, opt: true);
  static double? _$preferredWidth(StackPositionData v) => v.preferredWidth;
  static const Field<StackPositionData, double> _f$preferredWidth =
      Field('preferredWidth', _$preferredWidth, opt: true);
  static double? _$height(StackPositionData v) => v.height;
  static const Field<StackPositionData, double> _f$height =
      Field('height', _$height, opt: true);
  static double? _$preferredHeight(StackPositionData v) => v.preferredHeight;
  static const Field<StackPositionData, double> _f$preferredHeight =
      Field('preferredHeight', _$preferredHeight, opt: true);

  @override
  final MappableFields<StackPositionData> fields = const {
    #id: _f$id,
    #layer: _f$layer,
    #offset: _f$offset,
    #keepAlive: _f$keepAlive,
    #width: _f$width,
    #preferredWidth: _f$preferredWidth,
    #height: _f$height,
    #preferredHeight: _f$preferredHeight,
  };

  static StackPositionData _instantiate(DecodingData data) {
    return StackPositionData(
        id: data.dec(_f$id),
        layer: data.dec(_f$layer),
        offset: data.dec(_f$offset),
        keepAlive: data.dec(_f$keepAlive),
        width: data.dec(_f$width),
        preferredWidth: data.dec(_f$preferredWidth),
        height: data.dec(_f$height),
        preferredHeight: data.dec(_f$preferredHeight));
  }

  @override
  final Function instantiate = _instantiate;

  static StackPositionData fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<StackPositionData>(map);
  }

  static StackPositionData fromJson(String json) {
    return ensureInitialized().decodeJson<StackPositionData>(json);
  }
}

mixin StackPositionDataMappable {
  String toJson() {
    return StackPositionDataMapper.ensureInitialized()
        .encodeJson<StackPositionData>(this as StackPositionData);
  }

  Map<String, dynamic> toMap() {
    return StackPositionDataMapper.ensureInitialized()
        .encodeMap<StackPositionData>(this as StackPositionData);
  }

  StackPositionDataCopyWith<StackPositionData, StackPositionData,
          StackPositionData>
      get copyWith =>
          _StackPositionDataCopyWithImpl<StackPositionData, StackPositionData>(
              this as StackPositionData, $identity, $identity);
  @override
  String toString() {
    return StackPositionDataMapper.ensureInitialized()
        .stringifyValue(this as StackPositionData);
  }

  @override
  bool operator ==(Object other) {
    return StackPositionDataMapper.ensureInitialized()
        .equalsValue(this as StackPositionData, other);
  }

  @override
  int get hashCode {
    return StackPositionDataMapper.ensureInitialized()
        .hashValue(this as StackPositionData);
  }
}

extension StackPositionDataValueCopy<$R, $Out>
    on ObjectCopyWith<$R, StackPositionData, $Out> {
  StackPositionDataCopyWith<$R, StackPositionData, $Out>
      get $asStackPositionData => $base
          .as((v, t, t2) => _StackPositionDataCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class StackPositionDataCopyWith<$R, $In extends StackPositionData,
    $Out> implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? id,
      int? layer,
      Offset? offset,
      bool? keepAlive,
      double? width,
      double? preferredWidth,
      double? height,
      double? preferredHeight});
  StackPositionDataCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
      Then<$Out2, $R2> t);
}

class _StackPositionDataCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, StackPositionData, $Out>
    implements StackPositionDataCopyWith<$R, StackPositionData, $Out> {
  _StackPositionDataCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<StackPositionData> $mapper =
      StackPositionDataMapper.ensureInitialized();
  @override
  $R call(
          {String? id,
          int? layer,
          Offset? offset,
          bool? keepAlive,
          Object? width = $none,
          Object? preferredWidth = $none,
          Object? height = $none,
          Object? preferredHeight = $none}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (layer != null) #layer: layer,
        if (offset != null) #offset: offset,
        if (keepAlive != null) #keepAlive: keepAlive,
        if (width != $none) #width: width,
        if (preferredWidth != $none) #preferredWidth: preferredWidth,
        if (height != $none) #height: height,
        if (preferredHeight != $none) #preferredHeight: preferredHeight
      }));
  @override
  StackPositionData $make(CopyWithData data) => StackPositionData(
      id: data.get(#id, or: $value.id),
      layer: data.get(#layer, or: $value.layer),
      offset: data.get(#offset, or: $value.offset),
      keepAlive: data.get(#keepAlive, or: $value.keepAlive),
      width: data.get(#width, or: $value.width),
      preferredWidth: data.get(#preferredWidth, or: $value.preferredWidth),
      height: data.get(#height, or: $value.height),
      preferredHeight: data.get(#preferredHeight, or: $value.preferredHeight));

  @override
  StackPositionDataCopyWith<$R2, StackPositionData, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _StackPositionDataCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
