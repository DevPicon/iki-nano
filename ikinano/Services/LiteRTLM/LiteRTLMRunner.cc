#include "LiteRTLMRunner.h"
#include "LiteRTLM.h"
#include <iostream>
#include <mutex>

class LiteRTLMRunner::Impl {
public:
    LiteRtLmEngine* engine = nullptr;
    LiteRtLmConversation* conversation = nullptr;

    Impl() {}
    ~Impl() {
        Unload();
    }

    bool Initialize(const Config& config) {
        Unload();
        
        const char* backend_str = "cpu";
        switch (config.backend) {
            case LiteRTLMRunner::Backend::GPU: backend_str = "gpu"; break;
            case LiteRTLMRunner::Backend::Automatic: backend_str = "gpu"; break; // Default to GPU if automatic
            case LiteRTLMRunner::Backend::CPU: default: backend_str = "cpu"; break;
        }

        LiteRtLmEngineSettings* settings = litert_lm_engine_settings_create(
            config.model_path.c_str(),
            backend_str,
            nullptr, // vision_backend
            nullptr  // audio_backend
        );

        if (!settings) return false;

        litert_lm_engine_settings_set_max_num_tokens(settings, config.max_tokens);
        litert_lm_engine_settings_set_enable_speculative_decoding(settings, config.enable_speculative_decoding);

        engine = litert_lm_engine_create(settings);
        litert_lm_engine_settings_delete(settings);

        if (!engine) return false;

        conversation = litert_lm_conversation_create(engine, nullptr);
        return conversation != nullptr;
    }

    std::string SendMessage(const std::string& text) {
        if (!conversation) return "Error: Conversation not initialized";

        LiteRtLmJsonResponse* response = litert_lm_conversation_send_message(
            conversation, text.c_str(), nullptr
        );

        if (!response) return "Error: Failed to get response";

        std::string result = litert_lm_json_response_get_string(response);
        litert_lm_json_response_delete(response);
        return result;
    }

    struct AsyncContext {
        std::function<void(const std::string&)> on_token;
        std::function<void(bool, const std::string&)> on_completion;
    };

    void SendMessageAsync(const std::string& text,
                          std::function<void(const std::string&)> on_token,
                          std::function<void(bool, const std::string&)> on_completion) {
        if (!conversation) {
            if (on_completion) on_completion(false, "Conversation not initialized");
            return;
        }

        AsyncContext* context = new AsyncContext{on_token, on_completion};

        int result = litert_lm_conversation_send_message_stream(
            conversation,
            text.c_str(),
            nullptr,
            [](void* callback_data, const char* chunk, bool is_final, const char* error_msg) {
                AsyncContext* ctx = static_cast<AsyncContext*>(callback_data);
                if (error_msg) {
                    if (ctx->on_completion) ctx->on_completion(false, error_msg);
                    delete ctx;
                } else {
                    if (chunk && ctx->on_token) {
                        ctx->on_token(chunk);
                    }
                    if (is_final) {
                        if (ctx->on_completion) ctx->on_completion(true, "");
                        delete ctx;
                    }
                }
            },
            context
        );

        if (result != 0) {
            if (on_completion) on_completion(false, "Failed to start stream");
            delete context;
        }
    }

    void ResetConversation() {
        if (engine && conversation) {
            litert_lm_conversation_delete(conversation);
            conversation = litert_lm_conversation_create(engine, nullptr);
        }
    }

    void Unload() {
        if (conversation) {
            litert_lm_conversation_delete(conversation);
            conversation = nullptr;
        }
        if (engine) {
            litert_lm_engine_delete(engine);
            engine = nullptr;
        }
    }
};

LiteRTLMRunner::LiteRTLMRunner() : impl_(std::make_unique<Impl>()) {}
LiteRTLMRunner::~LiteRTLMRunner() = default;

bool LiteRTLMRunner::Initialize(const Config& config) {
    return impl_->Initialize(config);
}

std::string LiteRTLMRunner::SendMessage(const std::string& text) {
    return impl_->SendMessage(text);
}

void LiteRTLMRunner::SendMessageAsync(const std::string& text,
                                      std::function<void(const std::string&)> on_token,
                                      std::function<void(bool, const std::string&)> on_completion) {
    impl_->SendMessageAsync(text, on_token, on_completion);
}

void LiteRTLMRunner::ResetConversation() {
    impl_->ResetConversation();
}

void LiteRTLMRunner::Unload() {
    impl_->Unload();
}
