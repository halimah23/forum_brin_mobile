import 'package:flutter/material.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart';

typedef IconWidgetBuilder = Widget Function(Color color, double size);

enum MemberMenuType {
  home(
    'Beranda',
    _homeIcon,
    _homeIcon,
  ),
  forum(
    'Forum',
    _forumIcon,
    _forumIcon,
  ),
  profile(
    'Profil',
    _profileIcon,
    _profileIcon,
  );

  final String label;
  final IconWidgetBuilder unselectedIconBuilder;
  final IconWidgetBuilder selectedIconBuilder;

  const MemberMenuType(this.label, this.unselectedIconBuilder, this.selectedIconBuilder);

  static Widget _homeIcon(Color color, double size) => Home(color: color, width: size, height: size);
  static Widget _forumIcon(Color color, double size) => ChatLines(color: color, width: size, height: size);
  static Widget _profileIcon(Color color, double size) => User(color: color, width: size, height: size);
}

enum AdminMenuType {
  home(
    'Beranda',
    _homeIcon,
    _homeIcon,
  ),
  tickets(
    'Layanan SDM',
    _inboxIcon,
    _inboxIcon,
  ),
  forum(
    'Forum',
    _forumIcon,
    _forumIcon,
  ),
  profile(
    'Profil',
    _profileIcon,
    _profileIcon,
  );

  final String label;
  final IconWidgetBuilder unselectedIconBuilder;
  final IconWidgetBuilder selectedIconBuilder;

  const AdminMenuType(this.label, this.unselectedIconBuilder, this.selectedIconBuilder);

  static Widget _homeIcon(Color color, double size) => Home(color: color, width: size, height: size);
  static Widget _inboxIcon(Color color, double size) => MailIn(color: color, width: size, height: size);
  static Widget _forumIcon(Color color, double size) => ChatLines(color: color, width: size, height: size);
  static Widget _profileIcon(Color color, double size) => User(color: color, width: size, height: size);
}

enum KetuaTimMenuType {
  home(
    'Beranda',
    _homeIcon,
    _homeIcon,
  ),
  disposition(
    'Tiket SDM',
    _sendIcon,
    _sendIcon,
  ),
  forum(
    'Forum',
    _forumIcon,
    _forumIcon,
  ),
  profile(
    'Profil',
    _profileIcon,
    _profileIcon,
  );

  final String label;
  final IconWidgetBuilder unselectedIconBuilder;
  final IconWidgetBuilder selectedIconBuilder;

  const KetuaTimMenuType(this.label, this.unselectedIconBuilder, this.selectedIconBuilder);

  static Widget _homeIcon(Color color, double size) => Home(color: color, width: size, height: size);
  static Widget _sendIcon(Color color, double size) => Send(color: color, width: size, height: size);
  static Widget _forumIcon(Color color, double size) => ChatLines(color: color, width: size, height: size);
  static Widget _profileIcon(Color color, double size) => User(color: color, width: size, height: size);
}

enum EksekutifMenuType {
  home(
    'Beranda',
    _homeIcon,
    _homeIcon,
  ),
  monitor(
    'Monitoring',
    _graphIcon,
    _graphIcon,
  ),
  forum(
    'Forum',
    _forumIcon,
    _forumIcon,
  ),
  profile(
    'Profil',
    _profileIcon,
    _profileIcon,
  );

  final String label;
  final IconWidgetBuilder unselectedIconBuilder;
  final IconWidgetBuilder selectedIconBuilder;

  const EksekutifMenuType(this.label, this.unselectedIconBuilder, this.selectedIconBuilder);

  static Widget _homeIcon(Color color, double size) => Home(color: color, width: size, height: size);
  static Widget _graphIcon(Color color, double size) => GraphUp(color: color, width: size, height: size);
  static Widget _forumIcon(Color color, double size) => ChatLines(color: color, width: size, height: size);
  static Widget _profileIcon(Color color, double size) => User(color: color, width: size, height: size);
}

enum SuperAdminMenuType {
  home(
    'Beranda',
    _homeIcon,
    _homeIcon,
  ),
  audit(
    'Audit Tiket',
    _analyticsIcon,
    _analyticsIcon,
  ),
  forum(
    'Forum',
    _forumIcon,
    _forumIcon,
  ),
  profile(
    'Profil',
    _profileIcon,
    _profileIcon,
  );

  final String label;
  final IconWidgetBuilder unselectedIconBuilder;
  final IconWidgetBuilder selectedIconBuilder;

  const SuperAdminMenuType(this.label, this.unselectedIconBuilder, this.selectedIconBuilder);

  static Widget _homeIcon(Color color, double size) => Home(color: color, width: size, height: size);
  static Widget _analyticsIcon(Color color, double size) => StatsReport(color: color, width: size, height: size);
  static Widget _forumIcon(Color color, double size) => ChatLines(color: color, width: size, height: size);
  static Widget _profileIcon(Color color, double size) => User(color: color, width: size, height: size);
}
