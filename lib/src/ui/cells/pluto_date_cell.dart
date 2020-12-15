import 'dart:async';

import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';

import 'mixin_popup_cell.dart';

class PlutoDateCell extends StatefulWidget implements AbstractMixinPopupCell {
  final PlutoStateManager stateManager;
  final PlutoCell cell;
  final PlutoColumn column;

  PlutoDateCell({
    this.stateManager,
    this.cell,
    this.column,
  });

  @override
  _PlutoDateCellState createState() => _PlutoDateCellState();
}

class _PlutoDateCellState extends State<PlutoDateCell>
    with MixinPopupCell<PlutoDateCell> {
  PlutoStateManager popupStateManager;

  List<PlutoColumn> popupColumns = [];

  List<PlutoRow> popupRows = [];

  Icon icon = const Icon(
    Icons.date_range,
  );

  StreamSubscription<KeyManagerEvent> keyManagerStream;

  @override
  void dispose() {
    if (widget.column.type.date.startDate == null ||
        widget.column.type.date.endDate == null) {
      popupStateManager?.scroll?.vertical
          ?.removeOffsetChangedListener(_handleScroll);
    }

    keyManagerStream?.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    popupHeight = (8 * PlutoGridSettings.rowTotalHeight) +
        PlutoGridSettings.shadowLineSize +
        PlutoGridSettings.gridInnerSpacing;

    offsetOfScrollRowIdx = 3;

    popupColumns = _buildColumns();

    final defaultDate = DatetimeHelper.parseOrNullWithFormat(
            widget.cell.value, widget.column.type.date.format) ??
        DateTime.now();

    final startDate = widget.column.type.date.startDate ??
        DatetimeHelper.moveToFirstWeekday(
            defaultDate.add(const Duration(days: -60)));

    final endDate = widget.column.type.date.endDate ??
        DatetimeHelper.moveToLastWeekday(
            defaultDate.add(const Duration(days: 60)));

    final List<DateTime> days = DatetimeHelper.getDaysInBetween(
      startDate,
      endDate,
    );

    popupRows = _buildRows(days);

    createHeader = (PlutoStateManager stateManager) =>
        _DateCellHeader(stateManager: stateManager);
  }

  @override
  void onLoaded(PlutoOnLoadedEvent event) {
    popupStateManager = event.stateManager;

    popupStateManager.setSelectingMode(PlutoSelectingMode.none);

    if (widget.column.type.date.startDate == null ||
        widget.column.type.date.endDate == null) {
      event.stateManager.scroll.vertical
          .addOffsetChangedListener(_handleScroll);
    }

    keyManagerStream = popupStateManager.keyManager.subject.stream
        .listen(_handleGridFocusOnKey);

    super.onLoaded(event);
  }

  void _handleGridFocusOnKey(KeyManagerEvent keyManagerEvent) {
    if (keyManagerEvent.isKeyDownEvent) {
      if (keyManagerEvent.isUp) {
        if (popupStateManager.currentRowIdx == 0) {
          popupStateManager.prependRows(_getMoreRows(insertBefore: true));
          return;
        }
      } else if (keyManagerEvent.isDown) {
        if (popupStateManager.currentRowIdx ==
            popupStateManager.refRows.length - 1) {
          popupStateManager.appendRows(_getMoreRows());
          return;
        }
      }
    }
    return;
  }

  void _handleScroll() {
    if (widget.column.type.date.startDate == null &&
        popupStateManager.scroll.vertical.offset == 0) {
      popupStateManager.prependRows(_getMoreRows(insertBefore: true));
    } else if (widget.column.type.date.endDate == null &&
        popupStateManager.scroll.maxScrollVertical ==
            popupStateManager.scroll.vertical.offset) {
      popupStateManager.appendRows(_getMoreRows());
    }
  }

  List<PlutoColumn> _buildColumns() {
    final localeText = widget.stateManager.localeText;

    return [
      [localeText.sunday, '7'],
      [localeText.monday, '1'],
      [localeText.tuesday, '2'],
      [localeText.wednesday, '3'],
      [localeText.thursday, '4'],
      [localeText.friday, '5'],
      [localeText.saturday, '6'],
    ].map((e) {
      return PlutoColumn(
        title: e[0],
        field: e[1],
        type: PlutoColumnType.text(readOnly: true),
        width: 45,
        enableColumnDrag: false,
        enableSorting: false,
        enableContextMenu: false,
        formatter: (dynamic value) {
          var dateTime = DateTime.tryParse(value);
          return dateTime == null ? '' : dateTime.day.toString();
        },
      );
    }).toList(growable: false);
  }

  List<PlutoRow> _buildRows(List<DateTime> days) {
    List<PlutoRow> rows = [];

    while (days.isNotEmpty) {
      final Map<String, PlutoCell> cells = Map.fromIterable(
        ['7', '1', '2', '3', '4', '5', '6'],
        key: (e) => e,
        value: (e) {
          if (days.isEmpty) {
            return PlutoCell(value: '');
          }

          if (days.first.weekday.toString() != e) {
            return PlutoCell(value: '');
          }

          final DateTime day = days.removeAt(0);

          return PlutoCell(
            value: intl.DateFormat(widget.column.type.date.format).format(day),
          );
        },
      );

      rows.add(PlutoRow(cells: cells));
    }

    return rows;
  }

  List<PlutoRow> _getMoreRows({bool insertBefore = false}) {
    int firstDays;
    int lastDays;

    DateTime defaultDate;

    if (insertBefore) {
      firstDays = -30;
      lastDays = -1;

      defaultDate = DatetimeHelper.parseOrNullWithFormat(
          popupStateManager
              .refRows.first.cells.entries.first.value.value,
          widget.column.type.date.format);

      if (defaultDate == null) {
        return [];
      }

      if (widget.column.type.date.startDate != null &&
          defaultDate.isBefore(widget.column.type.date.startDate)) {
        defaultDate = widget.column.type.date.startDate;
      }
    } else {
      firstDays = 1;
      lastDays = 30;

      defaultDate = DatetimeHelper.parseOrNullWithFormat(
          popupStateManager.refRows.last.cells.entries.last.value.value,
          widget.column.type.date.format);

      if (defaultDate == null) {
        return [];
      }

      if (widget.column.type.date.endDate != null &&
          defaultDate.isAfter(widget.column.type.date.endDate)) {
        defaultDate = widget.column.type.date.endDate;
      }
    }

    final startDate = DatetimeHelper.moveToFirstWeekday(
        defaultDate.add(Duration(days: firstDays)));

    final endDate = DatetimeHelper.moveToLastWeekday(
        defaultDate.add(Duration(days: lastDays)));

    final List<DateTime> days = DatetimeHelper.getDaysInBetween(
      startDate,
      endDate,
    );

    return _buildRows(days);
  }
}

class _DateCellHeader extends PlutoStatefulWidget {
  final PlutoStateManager stateManager;

  _DateCellHeader({this.stateManager});

  @override
  _DateCellHeaderState createState() => _DateCellHeaderState();
}

abstract class _DateCellHeaderStateWithChange
    extends PlutoStateWithChange<_DateCellHeader> {
  PlutoCell currentCell;

  @override
  void onChange() {
    resetState((update) {
      currentCell = update<PlutoCell>(
        currentCell,
        widget.stateManager.currentCell,
        compare: identical,
      );
    });
  }
}

class _DateCellHeaderState extends _DateCellHeaderStateWithChange {
  String get currentDate {
    if (currentCell == null || currentCell.value.isEmpty) {
      return '';
    }

    return currentCell.value;
  }

  Color get textColor =>
      widget.stateManager.configuration.columnTextStyle.color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.stateManager.rowTotalHeight,
      padding:
          const EdgeInsets.symmetric(horizontal: PlutoGridSettings.cellPadding),
      alignment: Alignment.center,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          currentDate,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
