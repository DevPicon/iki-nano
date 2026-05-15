#include <stddef.h>

extern "C" {

void* LiteRtLmGemmaModelConstraintProvider_Create(void* config) {
    return nullptr;
}

void* LiteRtLmGemmaModelConstraintProvider_CreateConstraintFromTools(
    void* provider, const void* tools_json, size_t tools_json_len) {
    return nullptr;
}

void LiteRtLmGemmaModelConstraintProvider_Destroy(void* provider) {}

}
