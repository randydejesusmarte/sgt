import 'package:flutter/material.dart';
import 'package:taller_autos/models.dart';
import 'package:taller_autos/repositories.dart';

class ModeloBloc extends ChangeNotifier {
  final ModeloRepository _repo;

  List<Modelo> _modelos = [];
  bool _isLoading = false;
  String? _error;

  List<Modelo> get modelos => _modelos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ModeloBloc(this._repo);

  Future<void> loadModelos(int marcaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _modelos = await _repo.getByMarcaId(marcaId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addModelo(int marcaId, String nombre, int anio) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.create(Modelo(marcaId: marcaId, nombre: nombre, anio: anio));
      await loadModelos(marcaId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteModelo(int id, int marcaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.delete(id);
      await loadModelos(
          marcaId); // Reload for the current brand context usually
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
