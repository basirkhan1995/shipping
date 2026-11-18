
part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

// ---------------------------------------------------------
// Load products
// ---------------------------------------------------------
class LoadProductsEvent extends ProductsEvent {
  final int? proId;
  final String? input;

  const LoadProductsEvent({
    this.proId,
    this.input,
  });

  @override
  List<Object?> get props => [proId, input];
}

// ---------------------------------------------------------
// Load products with stock
// ---------------------------------------------------------
class LoadProductsStockEvent extends ProductsEvent {
  final int? proId;
  final int? noStock;
  final String? input;

  const LoadProductsStockEvent({
    this.proId,
    this.noStock,
    this.input,
  });

  @override
  List<Object?> get props => [proId, noStock, input];
}

// ---------------------------------------------------------
// Excel import
// ---------------------------------------------------------
class AddProductsFromExcelEvent extends ProductsEvent {
  final File excelFile;

  const AddProductsFromExcelEvent(this.excelFile);

  @override
  List<Object?> get props => [excelFile];
}

// ---------------------------------------------------------
// Add product
// ---------------------------------------------------------
class AddProductEvent extends ProductsEvent {
  final ProductsModel newProduct;

  const AddProductEvent(this.newProduct);

  @override
  List<Object?> get props => [newProduct];
}

// ---------------------------------------------------------
// Update product
// ---------------------------------------------------------
class UpdateProductEvent extends ProductsEvent {
  final ProductsModel newProduct;

  const UpdateProductEvent(this.newProduct);

  @override
  List<Object?> get props => [newProduct];
}

// ---------------------------------------------------------
// Upload product image
// ---------------------------------------------------------
class UploadProductImageEvent extends ProductsEvent {
  final int proId;
  final List<File> images;

  const UploadProductImageEvent(this.proId, this.images);

  @override
  List<Object?> get props => [proId, images];
}

// ---------------------------------------------------------
// Delete product
// ---------------------------------------------------------
class DeleteProductEvent extends ProductsEvent {
  final int proId;

  const DeleteProductEvent(this.proId);

  @override
  List<Object?> get props => [proId];
}
