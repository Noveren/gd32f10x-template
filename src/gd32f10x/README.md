```shell
- gd32f10x\
  - core\				# Cortex-M3
  - std\				# Standard Peripheral Libraray
  - gd32f10x.h			# 中断号、工具宏、外设基地址、gd32f10x_libopt.h
  - system_gd32f10x.h	# SystemInit, SystemCoreClockUpdate
  - system_gd32f10x.c
  - linker.ld			# 内存布局
  - startup.s			# Reset_Handler, g_pfnVectors
  - README.md
```

**设备类型**：不同设备类型的 GD32F10X 系列的设备拥有的外设不同，使用如下 **设备类型标识宏** 进行标识 `GD32F10X_MD`、`GD32F10X_HD`、`GD32F10X_XD`、`GD32F10X_CL`

+ **启动文件**：根据设备类型生成相应中断向量表 `g_pfnVectors`
+ **链接脚本**：根据设备类型生成选择 `FLASH` 和 `RAM` 的大小
+ TODO 考虑根据设备序列号生成启动文件和链接脚本到应用根目录，或手动编写适用于应用设备类型的启动文件和链接脚本





