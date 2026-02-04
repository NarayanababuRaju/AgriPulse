import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/thread_item.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/localization/language_provider.dart';


class RecursiveInsightThread extends ConsumerWidget {
  final List<ThreadItem> thread;

  const RecursiveInsightThread({super.key, required this.thread});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.read(languageProvider.notifier).translate;
    
    // Scroll to bottom on new items
    final scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: thread.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = thread[index];
        final isUser = item.role == 'user';
        final isLast = index == thread.length - 1;

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: _ThreadBubble(
            item: item,
            isUser: isUser,
            isLatest: isLast,
            tr: tr,
          ),
        );
      },
    );
  }
}

class _ThreadBubble extends StatelessWidget {
  final ThreadItem item;
  final bool isUser;
  final bool isLatest;

  const _ThreadBubble({
    required this.item,
    required this.isUser,
    required this.isLatest,
    required this.tr,
  });
  
  final String Function(String) tr;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser 
            ? ColorPalette.emeraldGreen.withValues(alpha: 0.1) 
            : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        border: Border.all(
          color: isUser ? ColorPalette.emeraldGreen.withValues(alpha: 0.2) : Colors.grey.shade200,
        ),
        boxShadow: isUser ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUser ? Icons.person : Icons.science,
                size: 16,
                color: isUser ? ColorPalette.emeraldGreen : ColorPalette.goldenSunlight,
              ),
              const SizedBox(width: 8),
              Text(
                isUser ? tr('role_user') : tr('role_ai'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUser ? ColorPalette.emeraldGreen : ColorPalette.textSecondary,
                ),
              ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(item.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Content Rendering
          if (isUser)
            Text(
              item.content,
              style: const TextStyle(
                fontSize: 15,
                color: ColorPalette.textPrimary,
                height: 1.4,
              ),
            )
          else
            _buildAIContent(context),
        ],
      ),
    );
  }
  
  Widget _buildAIContent(BuildContext context) {
    // If it's a full diagnosis (initial), show a summary card
    // If it's a refinement/reasoning, show text + markdown
    
    // Check metadata for 'disease_name' to distinguish initial results
    final meta = item.metadata;
    final isInitial = meta != null && meta.containsKey('disease_name') && !meta.containsKey('is_revised');
    
     if (isInitial) {
       final diseaseName = meta['disease_name'] ?? tr('analysis_complete');
       final confidence = (meta['confidence_score'] ?? 0.0).toDouble();
       final isHealthy = diseaseName.toLowerCase().contains('healthy') || 
                         diseaseName.toLowerCase().contains('no disease');
       
       return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            // Title Row with Confidence Score in right corner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    diseaseName,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textPrimary
                    ),
                  ),
                ),
                // Confidence Score with Standard Animation
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: confidence),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              value > 0.8 ? ColorPalette.emeraldGreen : Colors.orange
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${(value * 100).toInt()}% Confidence",
                          style: const TextStyle(
                            fontSize: 11, 
                            color: ColorPalette.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Health Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isHealthy ? ColorPalette.emeraldGreen.withValues(alpha: 0.1) : ColorPalette.rustRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isHealthy ? ColorPalette.emeraldGreen.withValues(alpha: 0.2) : ColorPalette.rustRed.withValues(alpha: 0.2)
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 14,
                    color: isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isHealthy ? "Healthy Crop" : "Issue Detected", // Ideally localized
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed,
                    ),
                  ),
                ],
              ),
            ),
           
           const SizedBox(height: 12),
           
           // Basic summary for history items
           if (!isLatest)
             Text(
               meta['treatment_recommendation']?.split('\\n')?.first ?? "",
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: ColorPalette.textSecondary),
             ),
           if (isLatest)
            MarkdownBody(data: meta['treatment_recommendation'] ?? item.content),
         ],
       );
    }
    
    return MarkdownBody(
      data: item.content,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(fontSize: 15, height: 1.5, color: ColorPalette.textPrimary),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
