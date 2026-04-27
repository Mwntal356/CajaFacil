import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';


class PromotionState {
  final String generatedFlyer;
  final bool isLoading;
  final String? error;

  PromotionState({this.generatedFlyer = '', this.isLoading = false, this.error});

  PromotionState copyWith({String? generatedFlyer, bool? isLoading, String? error}) {
    return PromotionState(
      generatedFlyer: generatedFlyer ?? this.generatedFlyer,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PromotionNotifier extends StateNotifier<PromotionState> {
  PromotionNotifier() : super(PromotionState());

  // Generar flyer atractivo con IA Gemini
  Future<void> generateFlyer(String description, {String? productName}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // PROMPT: Diseña un texto de promoción para el negocio "CajaFácil"
      final prompt = """
      Eres un experto en marketing digital para pequeños negocios. 
      Diseña un anuncio de WhatsApp (flyer de texto) IRRESISTIBLE para el negocio "CajaFácil".
      
      Producto/Oferta: ${productName ?? 'Gran Venta del Día'}
      Detalles específicos: $description
      
      Reglas de diseño del texto:
      1. Usa un encabezado con mayúsculas y emojis llamativos.
      2. Crea una sensación de escasez o urgencia (ej: "Solo por hoy", "Hasta agotar existencias").
      3. Usa viñetas claras para los beneficios o precios.
      4. TERMINA CON UNA LLAMADA A LA ACCIÓN (CTA) POTENTE (ej: "Escríbenos ahora", "Ven por el tuyo").
      5. Formato compatible con WhatsApp (negritas con asteriscos *texto*).
      """;

      // CLAVE DE API - Placeholder (El usuario debe proveer una real)
      const apiKey = 'YOUR_GEMINI_API_KEY'; 
      if (apiKey == 'YOUR_GEMINI_API_KEY') {
        // Simulación si no hay API Key para que el usuario vea cómo funcionaría
        await Future.delayed(const Duration(seconds: 2));
        state = state.copyWith(
          isLoading: false,
          generatedFlyer: "🚀 ¡GRAN OFERTA EN CAJAFÁCIL! 🚀\n\n$description\n\n¡No te lo pierdas! Ven hoy mismo o haz tu pedido por aquí. 📦✨",
        );
        return;
      }

      final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      state = state.copyWith(
        isLoading: false,
        generatedFlyer: response.text ?? 'No se pudo generar el texto.',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = PromotionState();
}

final promotionProvider = StateNotifierProvider<PromotionNotifier, PromotionState>((ref) {
  return PromotionNotifier();
});
