#!/usr/bin/env bash
set -e
WHICH="${1:-optimized}"
MODELS="${2:-ComfyUI/models}"
H=https://huggingface.co
mkdir -p "$MODELS"/{unet,diffusion_models,loras,text_encoders,vae}
cd "$MODELS"
g(){ [ -s "$2" ] || { echo "downloading $2"; curl -fL --retry 5 -C - -o "$2.part" "$1" && mv "$2.part" "$2"; }; }
common(){
  g $H/city96/umt5-xxl-encoder-gguf/resolve/main/umt5-xxl-encoder-Q5_K_M.gguf text_encoders/umt5-xxl-encoder-Q5_K_M.gguf
  g $H/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/VAE/Wan2.1_VAE.safetensors vae/wan_2.1_vae.safetensors
}
q4(){
  g $H/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q4_K_M.gguf unet/Wan2.2-I2V-A14B-HighNoise-Q4_K_M.gguf
  g $H/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q4_K_M.gguf unet/Wan2.2-I2V-A14B-LowNoise-Q4_K_M.gguf
}
lightning(){
  g $H/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors loras/lightning_i2v_high.safetensors
  g $H/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors loras/lightning_i2v_low.safetensors
}
fp16(){
  g $H/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors
  g $H/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors
}
case "$WHICH" in
  optimized) common; q4; lightning ;;
  pure-q4) common; q4 ;;
  pure-original) common; fp16 ;;
  all) common; q4; lightning; fp16 ;;
  *) echo "usage: download.sh optimized|pure-q4|pure-original|all [models folder]"; exit 1 ;;
esac
echo "done: $WHICH files are in $MODELS"
