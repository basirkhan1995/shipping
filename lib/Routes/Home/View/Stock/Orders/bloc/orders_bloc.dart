import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import '../../../../../../Services/repository.dart';
import '../model/orders_model.dart';

part 'orders_event.dart';
part 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final Repositories _repo;

  OrdersBloc(this._repo) : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<UpdateOrdersStatusEvent>(_onUpdateOrdersStatus);
    on<DeleteOrderEvent>(_onDeleteOrder);
    on<LoadOrderByIdEvent>(_getOrderById);
  }

  Future<void> _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersLoadingState());
    try {
      final orders = await _repo.getOrders(orderId: event.orderId);
      emit(OrdersLoadedState(orders));
    } catch(e) {
      emit(OrdersErrorState(e.toString()));
    }
  }

  Future<void> _getOrderById(LoadOrderByIdEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersLoadingState());
    try {
      final orders = await _repo.getOrderById(orderId: event.orderId);
      emit(SingleOrderLoadedState(orders));
    } catch(e) {
      emit(OrdersErrorState(e.toString()));
    }
  }

  Future<void> _onUpdateOrdersStatus(UpdateOrdersStatusEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersStatusUpdatingState());

    try {
      final response = await _repo.postOrderStatus(event.ordersData);

      final isSuccess = response['msg']?.toString().toLowerCase() == 'success';
      final message = response['message']?.toString() ??
          (isSuccess ? 'Order status updated successfully' : 'Failed to update order status');

      if (isSuccess) {
        emit(OrdersStatusUpdatedState(message));
        add(const LoadOrdersEvent()); // Refresh the list
      } else {
        emit(OrdersErrorState(message));
      }
    } catch (e) {
      emit(OrdersErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteOrder(DeleteOrderEvent event, Emitter<OrdersState> emit) async {
    final previousState = state;

    try {
      emit(OrdersDeletingState(event.orderId));

      final success = await _repo.deleteOrder(
        orderId: event.orderId,
        usrName: event.usrName,
        ref: event.ref,
        ordName: event.orderName,
      );

      if (success) {
        emit(OrdersDeletedState(
          true,
          message: '${event.orderName} order deleted successfully',
        ));
        event.completer?.complete('success');                             // ← new

        // Refresh the list after the current emission settles
        Future.microtask(() {
          if (!isClosed) add(const LoadOrdersEvent());
        });
      } else {
        final message =
            'Failed to delete ${event.orderName} order. The order may be verified or authorized.';
        emit(OrdersDeletedState(false, message: message));
        event.completer?.complete(message);                               // ← new

        if (previousState is OrdersLoadedState) {
          emit(previousState);
        } else {
          Future.microtask(() {
            if (!isClosed) add(const LoadOrdersEvent());
          });
        }
      }
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      final String errorMessage = (errorString.contains('authorized') ||
          errorString.contains('verified') ||
          errorString.contains('cannot delete'))
          ? 'Cannot delete order: The transaction is verified and cannot be deleted.'
          : 'Error deleting order: ${e.toString()}';

      emit(OrdersDeletedState(false, message: errorMessage));
      event.completer?.complete(errorMessage);                            // ← new

      if (previousState is OrdersLoadedState) {
        emit(previousState);
      } else {
        Future.microtask(() {
          if (!isClosed) add(const LoadOrdersEvent());
        });
      }
    }
  }
}