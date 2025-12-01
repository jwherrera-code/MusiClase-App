import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../models/profesor.dart';
import 'firestore_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();
  
  Usuario? _usuario;
  Usuario? get usuario => _usuario;

  Future<String?> registrarUsuario(String email, String password, String nombre, String tipo) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;
      
      if (user != null) {
        Usuario nuevoUsuario = Usuario(
          id: user.uid,
          nombre: nombre,
          email: email,
          tipo: tipo,
          fechaRegistro: DateTime.now(),
        );
        
        await _firestore.guardarUsuario(nuevoUsuario);
        if (tipo == 'profesor') {
          final profesor = Profesor(
            id: user.uid,
            usuarioId: user.uid,
            nombre: nombre,
            especialidad: '',
            instrumento: '',
            descripcion: 'Profesor en MusiClase',
            tarifaHora: 0.0,
            verificado: false,
            modalidades: ['online', 'presencial'],
          );
          await _firestore.guardarProfesor(profesor);
        }
        _usuario = nuevoUsuario;
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de autenticación: $e';
    }
    return 'Error desconocido';
  }

  Future<String?> iniciarSesion(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      User? user = result.user;
      
      if (user != null) {
        _usuario = await _firestore.obtenerUsuario(user.uid);
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error de autenticación: $e';
    }
    return 'Error desconocido';
  }

  Future<void> cerrarSesion() async {
    await _auth.signOut();
    _usuario = null;
    notifyListeners();
  }

  Future<void> crearAdminDemo() async {
    const primaryEmail = 'admin@musiclase.com';
    const fallbackEmail = 'admin_demo@musiclase.com';
    const password = 'admin123';

    Future<bool> _signInOrCreate(String email) async {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        final user = _auth.currentUser;
        if (user != null) {
          _usuario = await _firestore.obtenerUsuario(user.uid);
          notifyListeners();
          return true;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
          final u = cred.user;
          if (u != null) {
            final admin = Usuario(
              id: u.uid,
              nombre: 'Administrador',
              email: email,
              tipo: 'admin',
              fechaRegistro: DateTime.now(),
            );
            await _firestore.guardarUsuario(admin);
            _usuario = admin;
            notifyListeners();
            return true;
          }
        }
      }
      return false;
    }

    final okPrimary = await _signInOrCreate(primaryEmail);
    if (!okPrimary) {
      await _signInOrCreate(fallbackEmail);
    }
  }
}
