import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_chat_app/data/chat_repository.dart';
import 'package:my_chat_app/model/chat.dart';
import 'package:my_chat_app/view/home_view.dart';

class HomePresenter {
  final HomeView _view;
  final ChatRepository _chatRepository;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  List<Chat> _chats = [];

  HomePresenter(this._view) : _chatRepository = ChatRepository();

  List<Chat> get chats => _chats;

  void loadChats() {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) {
      _view.showMessage('User not authenticated.');
      return;
    }

    _view.showLoading();
    _chatRepository.getChatsForUser(currentUserId).listen(
      (chats) {
        _chats = chats;
        _view.displayChats(_chats);
        _view.hideLoading();
        _view.updateView();
      },
      onError: (error) {
        _view.showMessage('Error loading chats: $error');
        _view.hideLoading();
        _view.updateView();
      },
    );
  }

  Future<void> deleteChat(String chatId) async {
    _view.showLoading();
    try {
      await _chatRepository.deleteChat(chatId);
      _view.showMessage('Chat deleted successfully.');
      // Reload chats to update the UI
      loadChats();
    } catch (e) {
      _view.showMessage('Failed to delete chat: $e');
    } finally {
      _view.hideLoading();
    }
  }
}
