#import "LiteRTLMBridge.h"
#include "LiteRTLMRunner.h"
#include <memory>

@implementation LiteRTLMBridge {
    std::unique_ptr<LiteRTLMRunner> _runner;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _runner = std::make_unique<LiteRTLMRunner>();
    }
    return self;
}

- (BOOL)initializeWithModelPath:(NSString *)modelPath
                        backend:(LiteRTLMBackend)backend
     enableSpeculativeDecoding:(BOOL)enableSpeculativeDecoding
                     maxTokens:(NSInteger)maxTokens
                        error:(NSError * _Nullable * _Nullable)error {
    
    LiteRTLMRunner::Config config;
    config.model_path = std::string([modelPath UTF8String]);
    
    switch (backend) {
        case LiteRTLMBackendGPU:
            config.backend = LiteRTLMRunner::Backend::GPU;
            break;
        case LiteRTLMBackendAutomatic:
            config.backend = LiteRTLMRunner::Backend::Automatic;
            break;
        case LiteRTLMBackendCPU:
        default:
            config.backend = LiteRTLMRunner::Backend::CPU;
            break;
    }
    
    config.enable_speculative_decoding = enableSpeculativeDecoding;
    config.max_tokens = (int)maxTokens;
    
    if (_runner->Initialize(config)) {
        return YES;
    } else {
        if (error) {
            *error = [NSError errorWithDomain:@"com.ikinano.LiteRTLM"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize LiteRT-LM engine"}];
        }
        return NO;
    }
}

- (NSString *)sendMessage:(NSString *)text {
    std::string prompt = std::string([text UTF8String]);
    std::string response = _runner->SendMessage(prompt);
    return [NSString stringWithUTF8String:response.c_str()];
}

- (void)sendMessageAsync:(NSString *)text
                onToken:(void (^)(NSString *token))onToken
          onCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))onCompletion {
    
    std::string prompt = std::string([text UTF8String]);
    
    _runner->SendMessageAsync(prompt, 
        [onToken](const std::string& token) {
            NSString *nsToken = [NSString stringWithUTF8String:token.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                onToken(nsToken);
            });
        },
        [onCompletion](bool success, const std::string& errorMessage) {
            NSString *nsErrorMessage = errorMessage.empty() ? nil : [NSString stringWithUTF8String:errorMessage.c_str()];
            dispatch_async(dispatch_get_main_queue(), ^{
                onCompletion(success, nsErrorMessage);
            });
        }
    );
}

- (void)resetConversation {
    _runner->ResetConversation();
}

- (void)unload {
    _runner->Unload();
}

@end
