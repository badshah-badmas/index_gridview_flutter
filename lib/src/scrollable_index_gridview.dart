import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

class ScrollableIndexGridView extends StatefulWidget {
  const ScrollableIndexGridView.builder({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.childAspectRatio,
    required this.crossAxisCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.clipBehavior = Clip.hardEdge,
    this.controller,
    this.dragStartBehavior = DragStartBehavior.start,
    this.findChildIndexCallback,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.padding,
    this.physics,
    this.primary,
    this.restorationId,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.semanticChildCount,
    this.shrinkWrap = false,
    this.scrollStartFromIndex,
  });
  final Widget Function(BuildContext, int) itemBuilder;
  final DragStartBehavior dragStartBehavior;
  final Axis scrollDirection;
  final Clip clipBehavior;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final bool shrinkWrap;
  final bool reverse;
  final EdgeInsetsGeometry? padding;
  final IndexScrollController? controller;
  final ScrollPhysics? physics;
  final String? restorationId;
  final double? cacheExtent;
  final bool? primary;
  final int itemCount;
  final int? semanticChildCount;
  final int? Function(Key)? findChildIndexCallback;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final double childAspectRatio;
  final int crossAxisCount;
  final int? scrollStartFromIndex;

  @override
  State<ScrollableIndexGridView> createState() =>
      _ScrollableIndexGridViewState();
}

class _ScrollableIndexGridViewState extends State<ScrollableIndexGridView>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final _childHeightKey = GlobalKey();
  double _childHeight = 0;
  bool _isScrolling = false;
  Future<void> _scrollTo({
    required int index,
    double alignment = 0,
    required Duration duration,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) async {
    if (index > widget.itemCount - 1) {
      index = widget.itemCount - 1;
    }
    if (_isScrolling) {
      _stopScroll(canceled: true);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startScroll(
          index: index,
          alignment: alignment,
          duration: duration,
          curve: curve,
          opacityAnimationWeights: opacityAnimationWeights,
        );
      });
    } else {
      await _startScroll(
        index: index,
        alignment: alignment,
        duration: duration,
        curve: curve,
        opacityAnimationWeights: opacityAnimationWeights,
      );
    }
  }

  Future<void> _startScroll({
    required int index,
    required double alignment,
    required Duration duration,
    Curve curve = Curves.linear,
    required List<double> opacityAnimationWeights,
  }) async {
    if (_childHeight == 0) {
      final RenderBox? renderBox =
          _childHeightKey.currentContext?.findRenderObject() as RenderBox?;

      _childHeight = (renderBox?.size.height ?? _childHeight);
    }
    _isScrolling = true;

    await _scrollController.animateTo(
        ((index ~/ widget.crossAxisCount) -
                (widget.scrollStartFromIndex ?? 0)) *
            _childHeight,
        duration: duration,
        curve: curve);
    _isScrolling = false;
  }

  void _stopScroll({bool canceled = false}) {
    if (!_isScrolling) {
      return;
    }

    if (canceled) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.offset);
      }
    }
    _isScrolling = false;
  }

  void _jumpTo({required int index, required double alignment}) {
    if (_childHeight == 0) {
      final RenderBox? renderBox =
          _childHeightKey.currentContext?.findRenderObject() as RenderBox?;

      _childHeight = (renderBox?.size.height ?? _childHeight);
    }
    _scrollController.jumpTo(
      index * _childHeight,
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
  }

  @override
  void deactivate() {
    widget.controller?._detach();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (overscroll) {
        overscroll.disallowIndicator();
        return true;
      },
      child: GridView.builder(
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
        cacheExtent: widget.cacheExtent,
        clipBehavior: widget.clipBehavior,
        controller: _scrollController,
        dragStartBehavior: widget.dragStartBehavior,
        findChildIndexCallback: widget.findChildIndexCallback,
        itemCount: widget.itemCount,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        padding: widget.padding,
        physics: widget.physics,
        primary: widget.primary,
        restorationId: widget.restorationId,
        reverse: widget.reverse,
        scrollDirection: widget.scrollDirection,
        semanticChildCount: widget.semanticChildCount,
        shrinkWrap: widget.shrinkWrap,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio),
        itemBuilder: (context, index) {
          return SizedBox(
            key: index == 0 ? _childHeightKey : null,
            child: widget.itemBuilder(context, index),
          );
        },
      ),
    );
  }
}

class IndexScrollController {
  bool get isAttached => _scrollableListState != null;

  _ScrollableIndexGridViewState? _scrollableListState;

  void jumpTo({required int index, double alignment = 0}) {
    _scrollableListState!._jumpTo(index: index, alignment: alignment);
  }

  Future<void> scrollTo({
    required int index,
    double alignment = 0,
    required Duration duration,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) {
    assert(duration > Duration.zero);
    return _scrollableListState!._scrollTo(
      index: index,
      alignment: alignment,
      duration: duration,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
    );
  }

  void _attach(_ScrollableIndexGridViewState scrollableListState) {
    assert(_scrollableListState == null);
    _scrollableListState = scrollableListState;
  }

  void _detach() {
    _scrollableListState = null;
  }
}
