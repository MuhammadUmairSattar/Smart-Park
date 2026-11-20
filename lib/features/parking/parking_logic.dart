import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VehicleType {
  car('car', Icons.directions_car_rounded, 100, 50),
  motorcycle('motorcycle', Icons.two_wheeler_rounded, 30, 15),
  cycle('cycle', Icons.pedal_bike_rounded, 20, 10),
  rickshaw('rickshaw', Icons.electric_rickshaw_rounded, 50, 25),
  tractor('tractor', Icons.agriculture_rounded, 150, 70),
  mazda('mazda', Icons.local_shipping_outlined, 250, 100),
  dumper('dumper', Icons.fire_truck_rounded, 400, 150),
  truck('truck', Icons.local_shipping_rounded, 500, 200);

  final String labelKey;
  final IconData icon;
  final double baseFee;
  final double hourlyRate;
  const VehicleType(this.labelKey, this.icon, this.baseFee, this.hourlyRate);
}

enum TicketStatus { parked, checkedOut }

class ParkingTicket {
  final String tokenNumber;
  final VehicleType vehicleType;
  final String plateNumber;
  final String ownerName;
  final String locationSlot;
  final DateTime entryTime;
  final DateTime? exitTime;
  final TicketStatus status;

  const ParkingTicket({
    required this.tokenNumber,
    required this.vehicleType,
    required this.plateNumber,
    required this.ownerName,
    required this.locationSlot,
    required this.entryTime,
    this.exitTime,
    this.status = TicketStatus.parked,
  });

  double calculateTotalFee([DateTime? refTime]) {
    final end = exitTime ?? refTime ?? DateTime.now();
    final hours = end.difference(entryTime).inMinutes / 60.0;
    if (hours <= 1.0) return vehicleType.baseFee;
    return vehicleType.baseFee + ((hours - 1.0).ceil() * vehicleType.hourlyRate);
  }

  ParkingTicket copyWith({DateTime? exitTime, TicketStatus? status}) {
    return ParkingTicket(
      tokenNumber: tokenNumber,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
      ownerName: ownerName,
      locationSlot: locationSlot,
      entryTime: entryTime,
      exitTime: exitTime ?? this.exitTime,
      status: status ?? this.status,
    );
  }
}

class ParkingState {
  final List<ParkingTicket> tickets;
  final bool isLoading;
  const ParkingState({this.tickets = const [], this.isLoading = false});

  List<ParkingTicket> get activeTickets =>
      tickets.where((t) => t.status == TicketStatus.parked).toList();

  double get todayRevenue => tickets.fold(0.0, (sum, t) => sum + t.calculateTotalFee());

  ParkingState copyWith({List<ParkingTicket>? tickets, bool? isLoading}) {
    return ParkingState(tickets: tickets ?? this.tickets, isLoading: isLoading ?? this.isLoading);
  }
}

class ParkingNotifier extends Notifier<ParkingState> {
  @override
  ParkingState build() => const ParkingState();

  Future<ParkingTicket> issueTicket({
    required VehicleType type,
    required String plateNumber,
    required String ownerName,
    required String slot,
  }) async {
    state = state.copyWith(isLoading: true);
    final now = DateTime.now();
    final suffix = (now.millisecondsSinceEpoch % 9000 + 1000).toString();
    final tokenNo = 'TKN-${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}-$suffix';

    final ticket = ParkingTicket(
      tokenNumber: tokenNo,
      vehicleType: type,
      plateNumber: plateNumber.toUpperCase().trim(),
      ownerName: ownerName.trim(),
      locationSlot: slot.trim(),
      entryTime: now,
    );

    state = state.copyWith(tickets: [ticket, ...state.tickets], isLoading: false);
    return ticket;
  }

  ParkingTicket? checkOutTicket(String tokenNumber) {
    final idx = state.tickets.indexWhere((t) => t.tokenNumber == tokenNumber);
    if (idx == -1) return null;
    final updated = state.tickets[idx].copyWith(exitTime: DateTime.now(), status: TicketStatus.checkedOut);
    final updatedList = [...state.tickets];
    updatedList[idx] = updated;
    state = state.copyWith(tickets: updatedList);
    return updated;
  }
}

final parkingProvider = NotifierProvider<ParkingNotifier, ParkingState>(ParkingNotifier.new);
