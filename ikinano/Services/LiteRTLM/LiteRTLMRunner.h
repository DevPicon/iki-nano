#ifndef LITE_RT_LM_RUNNER_H
#define LITE_RT_LM_RUNNER_H

#include <string>
#include <functional>
#include <memory>
#include <vector>

namespace litert {
namespace lm {
class Engine;
class Conversation;
enum class Backend;
} // namespace lm
} // namespace litert

class LiteRTLMRunner {
public:
    enum class Backend {
        CPU,
        GPU,
        Automatic
    };

    struct Config {
        std::string model_path;
        Backend backend = Backend::CPU;
        bool enable_speculative_decoding = false;
        int max_tokens = 4096;
    };

    enum class ErrorCode {
        None = 0,
        InitializationFailed = 1,
        InferenceFailed = 2,
        StreamingFailed = 3,
        ModelNotFound = 4,
        OutOfMemory = 5,
        UnsupportedBackend = 6,
        InvalidInput = 7
    };

    LiteRTLMRunner();
    ~LiteRTLMRunner();

    bool Initialize(const Config& config);
    std::string SendMessage(const std::string& text);
    void SendMessageAsync(const std::string& text,
                          std::function<void(const std::string&)> on_token,
                          std::function<void(bool, const std::string&)> on_completion);
    
    void ResetConversation();
    void Unload();

private:
    class Impl;
    std::unique_ptr<Impl> impl_;
};

#endif // LITE_RT_LM_RUNNER_H
