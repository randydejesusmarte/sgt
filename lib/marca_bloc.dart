import 'package:flutter/material.dart';
import 'package:taller_autos/models.dart';
import 'package:taller_autos/repositories.dart';

class MarcaBloc extends ChangeNotifier {
  final MarcaRepository _repo;

  List<Marca> _marcas = [];
  bool _isLoading = false;
  String? _error;

  List<Marca> get marcas => _marcas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  MarcaBloc(this._repo);

  Future<void> loadMarcas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _marcas = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMarca(String nombre) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.create(Marca(nombre: nombre));
      await loadMarcas();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMarca(int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.delete(id);
      await loadMarcas();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
