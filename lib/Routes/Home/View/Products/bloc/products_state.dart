
part of 'products_bloc.dart';

sealed class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------
// Initial
// ---------------------------------------------------------
final class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

// ---------------------------------------------------------
// Loading
// ---------------------------------------------------------
final class ProductsLoadingState extends ProductsState {
  const ProductsLoadingState();
}

// ---------------------------------------------------------
// Products loaded
// ---------------------------------------------------------
final class ProductsLoadedState extends ProductsState {
  final List<ProductsModel> products;

  const ProductsLoadedState(this.products);

  @override
  List<Object?> get props => [products];
}

// ---------------------------------------------------------
// Single product loaded
// ---------------------------------------------------------
final class ProductSingleLoadedState extends ProductsState {
  final ProductsModel product;

  const ProductSingleLoadedState(this.product);

  @override
  List<Object?> get props => [product];
}

// ---------------------------------------------------------
// Stock products loaded
// ---------------------------------------------------------
final class ProductsStockLoadedState extends ProductsState {
  final List<ProductsStockModel> products;

  const ProductsStockLoadedState(this.products);

  @override
  List<Object?> get props => [products];
}

// ---------------------------------------------------------
// Excel uploaded
// ---------------------------------------------------------
final class ProductsExcelUploadedState extends ProductsState {
  final int inserted;
  final List<dynamic> skipped;
  final List<dynamic> errors;

  const ProductsExcelUploadedState({
    required this.inserted,
    required this.skipped,
    required this.errors,
  });

  @override
  List<Object?> get props => [
    inserted,
    skipped,
    errors,
  ];
}

// ---------------------------------------------------------
// Success
// ---------------------------------------------------------
final class ProductsSuccessState extends ProductsState {
  const ProductsSuccessState();
}

// ---------------------------------------------------------
// Error
// ---------------------------------------------------------
final class ProductsErrorState extends ProductsState {
  final String message;

  const ProductsErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
