import 'dart:ui';

enum DeviceScreenType {
  sm('sm'),
  md('md'),
  lg('lg'),
  xl('xl'),
  xxl('xxl'),
  xxxl('xxxl'),
  xxxxl('xxxxl');

  const DeviceScreenType(this.name);
  final String name;

  bool get isSm => name == 'sm';
  bool get isMd => name == 'md';
  bool get isLg => name == 'lg';
  bool get isXl => name == 'xl';
  bool get isXxl => name == 'xxl';
  bool get isXxxl => name == 'xxxl';
  bool get isXxxxl => name == 'xxxxl';

  double get breakpoint => switch (name) {
    'sm' => LayoutConstant.smBreakpoint,
    'md' => LayoutConstant.mdBreakpoint,
    'lg' => LayoutConstant.lgBreakpoint,
    'xl' => LayoutConstant.xlBreakpoint,
    'xxl' => LayoutConstant.xxlBreakpoint,
    'xxxl' => LayoutConstant.xxxlBreakpoint,
    'xxxxl' => LayoutConstant.xxxxlBreakpoint,
    _ => LayoutConstant.smBreakpoint,
  };

  Size get designSize => switch (name) {
    'sm' => LayoutConstant.smDesignSize,
    'md' => LayoutConstant.mdDesignSize,
    'lg' => LayoutConstant.lgDesignSize,
    'xl' => LayoutConstant.xlDesignSize,
    'xxl' => LayoutConstant.xxlDesignSize,
    'xxxl' => LayoutConstant.xxxlDesignSize,
    'xxxxl' => LayoutConstant.xxxxlDesignSize,
    _ => LayoutConstant.smDesignSize,
  };
}

class LayoutConstant {
  static const smBreakpoint = 640.0;
  static const mdBreakpoint = 768.0;
  static const lgBreakpoint = 1024.0;
  static const xlBreakpoint = 1280.0;
  static const xxlBreakpoint = 1536.0;
  static const xxxlBreakpoint = 1920.0;
  static const xxxxlBreakpoint = 2560.0;

  static const smDesignSize = Size(375, 812);
  static const mdDesignSize = Size(432, 768);
  static const lgDesignSize = Size(1024, 576);
  static const xlDesignSize = Size(1280, 720);
  static const xxlDesignSize = Size(1536, 864);
  static const xxxlDesignSize = Size(1920, 1080);
  static const xxxxlDesignSize = Size(2560, 1440);
}
