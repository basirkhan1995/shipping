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
    on<AddProductsFromExcelEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final response = await _repo.addProductFromExcel(
          excelFile: event.excelFile,
        );
        final msg = response["msg"];
        switch (msg) {
          case "success":
            final inserted = response["inserted"] as int? ?? 0;
            final skipped  = (response["skipped"] as List?) ?? const [];
            final errors   = (response["errors"]  as List?) ?? const [];

            emit(ProductsExcelUploadedState(
              inserted: inserted,
              skipped: skipped,
              errors: errors,
            ));
            return;

          case "failed":
            emit(ProductsErrorState(
              response["error"]?.toString() ?? "Upload failed",
            ));
            return;

          default:
            emit(ProductsErrorState(msg?.toString() ?? "Unknown response"));
            return;
        }
      } catch (e) {
        emit(ProductsErrorState(e.toString()));
      }
    });
    ///Products for sale invoice
    on<LoadProductsStockEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
        final products = await _repo.getProductStock(proId: event.proId, noStock: event.noStock, proName: event.input);
        emit(ProductsStockLoadedState(products));
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });

    on<UploadProductImageEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
       await _repo.uploadProductImage(proID: event.proId, images: event.images);
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });

    ///Product Settings and purchase invoice
    on<LoadProductsEvent>((event, emit) async{
      emit(ProductsLoadingState());
      try{
        await Future.delayed(Duration(milliseconds: 500));
        final products = await _repo.getProduct(input: event.input);
        emit(ProductsLoadedState(products));
      }catch(e){
        emit(ProductsErrorState(e.toString()));
      }
    });

    on<AddProductEvent>((event, emit) async {
      final tr = localizationService.loc;
      emit(ProductsLoadingState());
      try {
        final response = await _repo.addProduct(newProduct: event.newProduct);
        final msg = response["msg"];
        switch(msg) {
          case "success":
            emit(ProductsSuccessState());
            // Don't call add(LoadProductsEvent()) here as it might interfere
            // with the dialog closing
            return;
          case "exist":
            emit(ProductsErrorState(tr.productAlreadyExist));
            return;
          case "failed":
            emit(ProductsErrorState(msg));
            return;
          default:
            emit(ProductsErrorState(msg));
            return;
        }
      } catch(e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    on<UpdateProductEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final response = await _repo.updateProduct(newProduct: event.newProduct);
        final msg = response["msg"];
        switch(msg) {
          case "success":
            emit(ProductsSuccessState());
            return;
          case "empty":
            emit(ProductsErrorState(msg));
            return;
          case "failed":
            emit(ProductsErrorState(msg));
            return;
          default:
            emit(ProductsErrorState(msg));
            return;
        }
      } catch(e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

    on<DeleteProductEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final response = await _repo.deleteProduct(proId: event.proId);
        final msg = response["msg"];
        switch(msg) {
          case "success":
            emit(ProductsSuccessState());
            return;
          case "dependent":
            emit(ProductsErrorState(msg));
            return;
          case "failed":
            emit(ProductsErrorState(msg));
            return;
          default:
            emit(ProductsErrorState(msg));
            return;
        }
      } catch(e) {
        emit(ProductsErrorState(e.toString()));
      }
    });

  }
}
