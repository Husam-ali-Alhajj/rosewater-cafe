import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/avatar_service.dart';

/// The design's round profile avatar -- a purple gradient circle with a white
/// user icon and two stacked drop shadows (Figma Profile node 1216:2175 at
/// 80px, Edit Profile node 1217:2417 at 128px, identical styling) -- that
/// shows the member's real photo once one exists.
///
/// The photo lives in the private `avatars` bucket, so it's shown through a
/// short-lived signed URL fetched here. While that loads, or if it can't be
/// loaded (missing file, offline), the gradient + icon stays -- never a
/// broken image.
///
/// [previewBytes] takes priority over [avatarPath]: Edit Profile passes the
/// photo the user just picked (not uploaded yet) so they see it immediately.
class ProfileAvatar extends StatefulWidget {
  final double size;
  final String? avatarPath;
  final Uint8List? previewBytes;
  final AvatarService avatarService;

  const ProfileAvatar({
    super.key,
    required this.size,
    this.avatarPath,
    this.previewBytes,
    this.avatarService = const AvatarService(),
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _signedUrl;

  @override
  void initState() {
    super.initState();
    _resolveUrl();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarPath != widget.avatarPath) {
      _signedUrl = null;
      _resolveUrl();
    }
  }

  Future<void> _resolveUrl() async {
    final path = widget.avatarPath;
    if (path == null) return;
    final url = await widget.avatarService.signedUrl(path);
    // Ignore a result that arrives after the path changed or the widget went away.
    if (!mounted || widget.avatarPath != path) return;
    setState(() => _signedUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final icon = Center(child: Icon(Icons.person_outline, size: widget.size / 2, color: Colors.white));
    final preview = widget.previewBytes;
    final url = _signedUrl;

    Widget content = icon;
    if (preview != null) {
      content = Image.memory(preview, fit: BoxFit.cover, width: widget.size, height: widget.size);
    } else if (url != null) {
      content = Image.network(
        url,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        errorBuilder: (_, _, _) => icon,
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFC27AFF), Color(0xFF9810FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipOval(child: content),
    );
  }
}
