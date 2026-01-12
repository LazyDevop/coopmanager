import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationProvider extends ChangeNotifierProvider<NotificationViewModel> {
  NotificationProvider({super.key, required super.child}) 
      : super(create: (_) => NotificationViewModel());
}
