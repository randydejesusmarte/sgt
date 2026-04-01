import 'package:flutter/material.dart';
import 'package:taller_autos/models.dart';
import 'package:taller_autos/repositories.dart';

class PiezaBloc extends ChangeNotifier {
  final PiezaRepository _repo;

  List<Pieza> _piezas = [];
  bool _isLoading = false;
  String? _error;

  List<Pieza> get piezas => _piezas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PiezaBloc(this._repo);

  Future<void> loadPiezas(int modeloId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _piezas = await _repo.getByModeloId(modeloId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query, {int? modeloId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _piezas = await _repo.search(query, modeloId: modeloId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPieza(int modeloId, String nombre, String medidas,
      {String? codigo}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.create(Pieza(
          modeloId: modeloId,
          nombre: nombre,
          medidas: medidas,
          codigo: codigo));
      await loadPiezas(modeloId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePieza(int id, int modeloId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repo.delete(id);
      await loadPiezas(modeloId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
