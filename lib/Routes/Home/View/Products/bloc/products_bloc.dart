
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../../../Services/localization_services.dart';
import '../../../../../Services/repository.dart';
import '../model/product_model.dart';
import '../model/product_stock_model.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final Repositories _repo;

  ProductsBloc(this._repo) : super(ProductsInitial()) {
    // ---------------------------------------------------------
    // Import products from Excel
    // ---------------------------------------------------------
    on<AddProductsFromExcelEvent>((event, emit) async {
      emit(ProductsLoadingState());

      try {
        final response = await _repo.addProductFromExcel(
          excelFile: event.excelFile,
        );

        final msg = response['msg']?.toString();

        switch (msg) {
          case 'success':
            final inserted = _toInt(response['inserted']);

            final skipped = response['skipped'] is List
                ? List<dynamic>.from(response['skipped'])
                : <dynamic>[];

            final errors = response['errors'] is List
                ? List<dynamic>.from(response['errors'])
                : <dynamic>[];

            emit(
              ProductsExcelUploadedState(
                inserted: inserted,
                skipped: skipped,
                errors: errors,
              ),
            );
            break;

          case 'failed':
            emit(
              ProductsErrorState(
                response['error']?.toString() ?? 'Upload failed',
              ),
            );
            break;

          default:
            emit(
              ProductsErrorState(
                response['error']?.toString() ??
                    msg ??
                    'Unknown response',
              ),
            );
        }
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    // ---------------------------------------------------------
    // Products for sale invoice (stock products)
    // ---------------------------------------------------------
    on<LoadProductsStockEvent>((event, emit) async {
      emit(ProductsLoadingState());

      try {
        final products = await _repo.getProductStock(
          proId: event.proId,
          noStock: event.noStock,
          proName: event.input,
        );

        emit(ProductsStockLoadedState(products));
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    // ---------------------------------------------------------
    // Upload product images
    // ---------------------------------------------------------
    on<UploadProductImageEvent>((event, emit) async {
      emit(ProductsLoadingState());

      try {
        await _repo.uploadProductImage(
          proID: event.proId,
          images: event.images,
        );

        emit(ProductsSuccessState());
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    // ---------------------------------------------------------
    // Products for product settings and purchase invoice
    // ---------------------------------------------------------
    on<LoadProductsEvent>((event, emit) async {
      emit(ProductsLoadingState());

      try {
        final products = await _repo.getProduct(
          proId: event.proId,
          input: event.input,
        );

        if (event.proId != null) {
          if (products.isNotEmpty) {
            emit(ProductSingleLoadedState(products.first));
          } else {
            emit(ProductsLoadedState(products));
          }
        } else {
          emit(ProductsLoadedState(products));
        }
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    // ---------------------------------------------------------
    // Add product
    // ---------------------------------------------------------
    on<AddProductEvent>((event, emit) async {
      final tr = localizationService.loc;

      emit(ProductsLoadingState());

      try {
        final response = await _repo.addProduct(
          newProduct: event.newProduct,
        );

        final msg = response['msg']?.toString();

        switch (msg) {
          case 'success':
            emit(ProductsSuccessState());
            break;

          case 'exist':
            emit(ProductsErrorState(tr.productAlreadyExist));
            break;

          case 'failed':
            emit(
              ProductsErrorState(
                response['error']?.toString() ?? 'Failed to add product',
              ),
            );
            break;

          default:
            emit(
              ProductsErrorState(msg ?? 'Unknown response'),
            );
        }
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    // ---------------------------------------------------------
    // Update product
    // ---------------------------------------------------------
    on<UpdateProductEvent>((event, emit) async {
      emit(ProductsLoadingState());

      try {
        final response = await _repo.updateProduct(
          newProduct: event.newProduct,
        );

        final msg = response['msg']?.toString();

        switch (msg) {
          case 'success':
            emit(ProductsSuccessState());
            break;

          case 'empty':
            emit(ProductsErrorState(msg!));
            break;

          case 'failed':
            emit(
              ProductsErrorState(
                response['error']?.toString() ?? msg!,
              ),
            );
            break;

          default:
            emit(
              ProductsErrorState(msg ?? 'Unknown response'),
            );
        }
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    // ---------------------------------------------------------
    // Delete product
    // ---------------------------------------------------------
    on<DeleteProductEvent>((event, emit) async {
      emit(ProductsLoadingState());

      try {
        final response = await _repo.deleteProduct(
          proId: event.proId,
        );

        final msg = response['msg']?.toString();

        switch (msg) {
          case 'success':
            emit(ProductsSuccessState());
            break;

          case 'dependent':
            emit(
              ProductsErrorState(
                response['error']?.toString() ?? msg!,
              ),
            );
            break;

          case 'failed':
            emit(
              ProductsErrorState(
                response['error']?.toString() ?? msg!,
              ),
            );
            break;

          default:
            emit(
              ProductsErrorState(msg ?? 'Unknown response'),
            );
        }
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
