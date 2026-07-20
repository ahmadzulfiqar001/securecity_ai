import 'package:flutter/material.dart';

/// Single source of truth for the dashboard's 12 modules — consumed by both
/// the sidebar and the command palette so they can never drift apart.
class NavItem {
  const NavItem({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

const List<NavItem> kDashboardNavItems = [
  NavItem(label: 'AI Command Center', icon: Icons.dashboard_outlined, route: '/'),
  NavItem(label: 'Interactive Map', icon: Icons.map_outlined, route: '/map'),
  NavItem(label: 'Crime Heatmap', icon: Icons.local_fire_department_outlined, route: '/crime-heatmap'),
  NavItem(label: 'Emergency Queue', icon: Icons.emergency_outlined, route: '/emergency-queue'),
  NavItem(label: 'Computer Vision', icon: Icons.videocam_outlined, route: '/computer-vision'),
  NavItem(label: 'Analytics', icon: Icons.bar_chart_outlined, route: '/analytics'),
  NavItem(label: 'Reports', icon: Icons.description_outlined, route: '/reports'),
  NavItem(label: 'AI Predictions', icon: Icons.psychology_outlined, route: '/ai-predictions'),
  NavItem(label: 'Users', icon: Icons.people_outline, route: '/users'),
  NavItem(label: 'Notifications', icon: Icons.notifications_outlined, route: '/notifications'),
  NavItem(label: 'Settings', icon: Icons.settings_outlined, route: '/settings'),
  NavItem(label: 'System Logs', icon: Icons.receipt_long_outlined, route: '/system-logs'),
];
