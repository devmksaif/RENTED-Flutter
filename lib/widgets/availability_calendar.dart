import 'package:flutter/material.dart';
import '../services/rental_availability_service.dart';
import '../models/api_error.dart';
import '../config/app_theme.dart';

class AvailabilityCalendar extends StatefulWidget {
  final int productId;
  final bool isOwner;
  final Function(List<String>)? onDatesSelected;

  const AvailabilityCalendar({
    super.key,
    required this.productId,
    this.isOwner = false,
    this.onDatesSelected,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  final RentalAvailabilityService _availabilityService = RentalAvailabilityService();
  List<Map<String, dynamic>> _blockedDates = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  Set<String> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      final availability = await _availabilityService.getProductAvailability(
        widget.productId,
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );

      if (mounted) {
        setState(() {
          _blockedDates = List<Map<String, dynamic>>.from(
            availability['blocked_dates'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isDateBlocked(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return _blockedDates.any((blocked) => blocked['date'] == dateStr);
  }

  String _getBlockType(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    final blocked = _blockedDates.firstWhere(
      (b) => b['date'] == dateStr,
      orElse: () => {},
    );
    return blocked['block_type'] ?? '';
  }

  Color _getDateColor(DateTime date) {
    if (_isDateBlocked(date)) {
      final blockType = _getBlockType(date);
      return blockType == 'booked' ? Colors.red : Colors.orange;
    }
    if (_selectedDates.contains(date.toIso8601String().split('T')[0])) {
      return AppTheme.primaryGreen;
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Availability Calendar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                          );
                        });
                        _loadAvailability();
                      },
                    ),
                    Text(
                      '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _selectedMonth = DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                          );
                        });
                        _loadAvailability();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildCalendar(),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final firstDayOfWeek = firstDay.weekday;
    final daysInMonth = lastDay.day;

    return Column(
      children: [
        // Weekday headers
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        ...List.generate(
          ((daysInMonth + firstDayOfWeek - 1) / 7).ceil(),
          (weekIndex) {
            return Row(
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstDayOfWeek + 2;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  dayNumber,
                );
                final isBlocked = _isDateBlocked(date);
                final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                final dateColor = _getDateColor(date);

                return Expanded(
                  child: GestureDetector(
                    onTap: widget.isOwner && !isPast
                        ? () {
                            final dateStr = date.toIso8601String().split('T')[0];
                            setState(() {
                              if (_selectedDates.contains(dateStr)) {
                                _selectedDates.remove(dateStr);
                              } else {
                                _selectedDates.add(dateStr);
                              }
                            });
                            widget.onDatesSelected?.call(_selectedDates.toList());
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isPast
                            ? Colors.grey[200]
                            : dateColor != Colors.transparent
                                ? dateColor.withValues(alpha: 0.3)
                                : Colors.transparent,
                        border: Border.all(
                          color: isBlocked
                              ? dateColor
                              : dateColor != Colors.transparent
                                  ? dateColor
                                  : Colors.grey[300]!,
                          width: isBlocked ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                                color: isPast
                                    ? Colors.grey[400]
                                    : isBlocked
                                        ? dateColor
                                        : Colors.black87,
                              ),
                            ),
                            if (isBlocked)
                              Icon(
                                _getBlockType(date) == 'booked'
                                    ? Icons.event_busy
                                    : Icons.build,
                                size: 12,
                                color: dateColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(Colors.red, 'Booked'),
        _buildLegendItem(Colors.orange, 'Maintenance'),
        _buildLegendItem(AppTheme.primaryGreen, 'Available'),
        _buildLegendItem(Colors.grey[300]!, 'Past'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

