#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LiteRTLMBackend) {
    LiteRTLMBackendCPU,
    LiteRTLMBackendGPU,
    LiteRTLMBackendAutomatic
};

typedef NS_ENUM(NSInteger, LiteRTLMErrorCode) {
    LiteRTLMErrorCodeNone = 0,
    LiteRTLMErrorCodeInitializationFailed = 1,
    LiteRTLMErrorCodeInferenceFailed = 2,
    LiteRTLMErrorCodeStreamingFailed = 3,
    LiteRTLMErrorCodeModelNotFound = 4,
    LiteRTLMErrorCodeOutOfMemory = 5,
    LiteRTLMErrorCodeUnsupportedBackend = 6,
    LiteRTLMErrorCodeInvalidInput = 7
};

@interface LiteRTLMBridge : NSObject

- (instancetype)init;

- (BOOL)initializeWithModelPath:(NSString *)modelPath
                        backend:(LiteRTLMBackend)backend
     enableSpeculativeDecoding:(BOOL)enableSpeculativeDecoding
                        error:(NSError * _Nullable * _Nullable)error;

- (NSString *)sendMessage:(NSString *)text;

- (void)sendMessageAsync:(NSString *)text
                onToken:(void (^)(NSString *token))onToken
          onCompletion:(void (^)(BOOL success, NSString * _Nullable errorMessage))onCompletion;

- (void)resetConversation;

- (void)unload;

@end

NS_ASSUME_NONNULL_END
