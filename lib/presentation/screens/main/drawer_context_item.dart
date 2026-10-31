import 'package:flutter/material.dart';

enum DrawerDragKind { list, tag }

class DrawerDragItem {
  const DrawerDragItem(this.kind, this.id);
  final DrawerDragKind kind;
  final String id;
}

class DrawerContextAction {
  const DrawerContextAction(this.label, this.icon, this.onSelected);
  final String label;
  final IconData icon;
  final Future<void> Function() onSelected;
}

/// A non-modal menu leaves the original pointer available to the drag recognizer.
class DrawerContextItem extends StatefulWidget {
  const DrawerContextItem({
    super.key,
    required this.label,
    required this.icon,
    required this.actions,
    required this.child,
    this.dragItem,
    required this.onDragChanged,
    this.onDragPosition,
    required this.dismissMenus,
  });

  final String label;
  final IconData icon;
  final List<DrawerContextAction> actions;
  final Widget child;
  final DrawerDragItem? dragItem;
  final void Function(DrawerDragItem? item, bool moving) onDragChanged;
  final ValueChanged<Offset>? onDragPosition;
  final ValueNotifier<int> dismissMenus;

  @override
  State<DrawerContextItem> createState() => _DrawerContextItemState();
}

class _DrawerContextItemState extends State<DrawerContextItem> {
  final _moving = ValueNotifier(false);
  Offset _pressPosition = Offset.zero;
  OverlayEntry? _menu;

  @override
  void initState() {
    super.initState();
    widget.dismissMenus.addListener(_closeMenu);
  }

  void _closeMenu() {
    _menu?.remove();
    _menu?.dispose();
    _menu = null;
  }

  @override
  void dispose() {
    widget.dismissMenus.removeListener(_closeMenu);
    _closeMenu();
    _moving.dispose();
    super.dispose();
  }

  void _showMenu(Offset globalPosition) {
    _closeMenu();
    final overlay = Overlay.of(context);
    final box = overlay.context.findRenderObject()! as RenderBox;
    final position = box.globalToLocal(globalPosition);
    final width = (box.size.width - 24).clamp(0.0, 232.0);
    final left = position.dx.clamp(12.0, box.size.width - width - 12);
    final height = widget.actions.length * 52.0 + 8;
    final top = position.dy.clamp(12.0, box.size.height - height - 12);
    _menu = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeMenu,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: width,
            child: Material(
              key: const ValueKey('drawer-context-menu'),
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final action in widget.actions)
                      ListTile(
                        dense: true,
                        leading: Icon(action.icon),
                        title: Text(action.label),
                        onTap: () async {
                          _closeMenu();
                          await action.onSelected();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_menu!);
  }

  void _trackMovement(Offset position) {
    if (!_moving.value && (position - _pressPosition).distance > 12) {
      _moving.value = true;
      _closeMenu();
      widget.onDragChanged(widget.dragItem, true);
    }
    if (_moving.value) widget.onDragPosition?.call(position);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dragItem == null) {
      return GestureDetector(
        onLongPressStart: (details) {
          _pressPosition = details.globalPosition;
          _moving.value = false;
          _showMenu(_pressPosition);
        },
        onLongPressMoveUpdate: (details) =>
            _trackMovement(details.globalPosition),
        child: widget.child,
      );
    }
    return Listener(
      onPointerDown: (event) => _pressPosition = event.position,
      child: LongPressDraggable<DrawerDragItem>(
        data: widget.dragItem,
        maxSimultaneousDrags: 1,
        onDragStarted: () {
          _moving.value = false;
          widget.onDragChanged(widget.dragItem, false);
          _showMenu(_pressPosition);
        },
        onDragUpdate: (details) => _trackMovement(details.globalPosition),
        onDragEnd: (_) {
          if (_moving.value) _closeMenu();
          widget.onDragChanged(null, false);
        },
        feedback: ValueListenableBuilder<bool>(
          valueListenable: _moving,
          builder: (_, moving, child) =>
              Opacity(opacity: moving ? .9 : 0, child: child),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 240,
              child: ListTile(
                leading: Icon(widget.icon),
                title: Text(widget.label),
              ),
            ),
          ),
        ),
        childWhenDragging: ValueListenableBuilder<bool>(
          valueListenable: _moving,
          builder: (_, moving, child) =>
              Opacity(opacity: moving ? .35 : 1, child: child),
          child: widget.child,
        ),
        child: widget.child,
      ),
    );
  }
}
