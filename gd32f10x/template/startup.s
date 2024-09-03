/******************************************************************
 @brief   CMSIS-Core Device Startup File for Cortex-M3 Device
          GD32F103C8T6
 @version V0.0.1
******************************************************************/

                .syntax unified
                .arch armv7-m
                .fpu softvfp
                .thumb

/*****************************************************************
 @param[in]: _estack
 @param[in]: _sidata
 @param[in]: _sdata
 @param[in]: _edata
 @param[in]: _sbss
 @param[in]: _ebss
 @param[in]: SystemInit
 @param[in]: main
******************************************************************/
                .word _sidata
                .word _sdata
                .word _edata
                .word _sbss
                .word _ebss

                .section .text.Reset_Handler
                .weak Reset_Handler
                .type Reset_Handler, %function
Reset_Handler:
                /* 1. 初始化进程堆栈指针 */
                ldr r0, =_estack
                msr psp, r0
                /* 2. 全局变量: 初始化 */
                ldr r0, =_sdata
                ldr r1, =_edata
                ldr r2, =_sidata
                movs r3, #0
                b LoopCopyDataInit
CopyDataInit:
                ldr r4, [r2, r3]
                str r4, [r0, r3]
                adds r3, r3, #4
LoopCopyDataInit:
                adds r4, r0, r3
                cmp r4, r1
                bcc CopyDataInit
                /* 3. 全局变量: 填充零 */
                ldr r2, =_sbss
                ldr r4, =_ebss
                movs r3, #0
                b LoopFillZero
FillZero:
                str r3, [r2]
                adds r2, r2, #4
LoopFillZero:
                cmp r2, r4
                bcc FillZero
                /* 4. 系统初始化 */
                bl SystemInit
                /* 5. 进入到主函数 */
                bl main
                /* 6. TODO 主函数错误处理 */
                bx lr
                .size Reset_Handler, .-Reset_Handler


/*****************************************************************
 @brief: Default Handler
******************************************************************/
                .section .text.Default_Handler,"ax",%progbits
Default_Handler:
InfiniteLoop:
                b InfiniteLoop
                .size Default_Handler, .-Default_Handler


/*****************************************************************
 @brief: Vector Table for GD32F103C8T6; The name of the section
         'isr_vector' should be same with startup
 @param[in]: _estack
******************************************************************/
                .global g_pfnVectors

                .section .isr_vector,"a",%progbits
                .type     g_pfnVectors,%object
                .size     g_pfnVectors, .-g_pfnVectors

g_pfnVectors:
                .word     _estack
                .word     Reset_Handler
                /* 异常 */
                .word     NMI_Handler
                .word     HardFault_Handler
                .word     MemManage_Handler
                .word     BusFault_Handler
                .word     UsageFault_Handler
                .word     0
                .word     0
                .word     0
                .word     0
                .word     SVC_Handler
                .word     DebugMon_Handler
                .word     0
                .word     PendSV_Handler
                .word     SysTick_Handler

                /* 中断 */
                .word     WWDGT_IRQHandler
                .word     LVD_IRQHandler
                .word     TAMPER_IRQHandler
                .word     RTC_IRQHandler
                .word     FMC_IRQHandler
                .word     RCU_IRQHandler
                .word     EXTI0_IRQHandler
                .word     EXTI1_IRQHandler
                .word     EXTI2_IRQHandler
                .word     EXTI3_IRQHandler
                .word     EXTI4_IRQHandler

                .word     EXTI4_IRQHandler
                .word     DMA0_Channel0_IRQHandler
                .word     DMA0_Channel1_IRQHandler
                .word     DMA0_Channel2_IRQHandler
                .word     DMA0_Channel3_IRQHandler
                .word     DMA0_Channel4_IRQHandler
                .word     DMA0_Channel5_IRQHandler
                .word     DMA0_Channel6_IRQHandler
                .word     ADC0_1_IRQHandler
                .word     USBD_HP_CAN0_TX_IRQHandler
                .word     USBD_LP_CAN0_RX0_IRQHandler
                .word     CAN0_RX1_IRQHandler
                .word     CAN0_EWMC_IRQHandler
                .word     EXTI5_9_IRQHandler
                .word     TIMER0_BRK_IRQHandler
                .word     TIMER0_UP_IRQHandler
                .word     TIMER0_TRG_CMT_IRQHandler
                .word     TIMER0_Channel_IRQHandler
                .word     TIMER1_IRQHandler
                .word     TIMER2_IRQHandler
                .word     TIMER3_IRQHandler
                .word     I2C0_EV_IRQHandler
                .word     I2C0_ER_IRQHandler
                .word     I2C1_EV_IRQHandler
                .word     I2C1_ER_IRQHandler
                .word     SPI0_IRQHandler
                .word     SPI1_IRQHandler
                .word     USART0_IRQHandler
                .word     USART1_IRQHandler
                .word     USART2_IRQHandler
                .word     EXTI10_15_IRQHandler
                .word     RTC_Alarm_IRQHandler
                .word     USBD_WKUP_IRQHandler
                .word     0
                .word     0
                .word     0
                .word     0
                .word     0
                .word     EXMC_IRQHandler

                /* 默认中断处理函数 */
                .macro Set_Default_Handler Handler_Name
                .weak \Handler_Name
                .set  \Handler_Name, Default_Handler
                .endm
                /* 异常 */
                Set_Default_Handler  NMI_Handler
                Set_Default_Handler  HardFault_Handler
                Set_Default_Handler  MemManage_Handler
                Set_Default_Handler  BusFault_Handler
                Set_Default_Handler  UsageFault_Handler
                Set_Default_Handler  SVC_Handler
                Set_Default_Handler  DebugMon_Handler
                Set_Default_Handler  PendSV_Handler
                Set_Default_Handler  SysTick_Handler
                /* 中断 */
                Set_Default_Handler  WWDGT_IRQHandler
                Set_Default_Handler  LVD_IRQHandler
                Set_Default_Handler  TAMPER_IRQHandler
                Set_Default_Handler  RTC_IRQHandler
                Set_Default_Handler  FMC_IRQHandler
                Set_Default_Handler  RCU_IRQHandler
                Set_Default_Handler  EXTI0_IRQHandler
                Set_Default_Handler  EXTI1_IRQHandler
                Set_Default_Handler  EXTI2_IRQHandler
                Set_Default_Handler  EXTI3_IRQHandler
                Set_Default_Handler  EXTI4_IRQHandler
                Set_Default_Handler  DMA0_Channel0_IRQHandler
                Set_Default_Handler  DMA0_Channel1_IRQHandler
                Set_Default_Handler  DMA0_Channel2_IRQHandler
                Set_Default_Handler  DMA0_Channel3_IRQHandler
                Set_Default_Handler  DMA0_Channel4_IRQHandler
                Set_Default_Handler  DMA0_Channel5_IRQHandler
                Set_Default_Handler  DMA0_Channel6_IRQHandler
                Set_Default_Handler  ADC0_1_IRQHandler
                Set_Default_Handler  USBD_HP_CAN0_TX_IRQHandler
                Set_Default_Handler  USBD_LP_CAN0_RX0_IRQHandler
                Set_Default_Handler  CAN0_RX1_IRQHandler
                Set_Default_Handler  CAN0_EWMC_IRQHandler
                Set_Default_Handler  EXTI5_9_IRQHandler
                Set_Default_Handler  TIMER0_BRK_IRQHandler
                Set_Default_Handler  TIMER0_UP_IRQHandler
                Set_Default_Handler  TIMER0_TRG_CMT_IRQHandler
                Set_Default_Handler  TIMER0_Channel_IRQHandler
                Set_Default_Handler  TIMER1_IRQHandler
                Set_Default_Handler  TIMER2_IRQHandler
                Set_Default_Handler  TIMER3_IRQHandler
                Set_Default_Handler  I2C0_EV_IRQHandler
                Set_Default_Handler  I2C0_ER_IRQHandler
                Set_Default_Handler  I2C1_EV_IRQHandler
                Set_Default_Handler  I2C1_ER_IRQHandler
                Set_Default_Handler  SPI0_IRQHandler
                Set_Default_Handler  SPI1_IRQHandler
                Set_Default_Handler  USART0_IRQHandler
                Set_Default_Handler  USART1_IRQHandler
                Set_Default_Handler  USART2_IRQHandler
                Set_Default_Handler  EXTI10_15_IRQHandler
                Set_Default_Handler  RTC_Alarm_IRQHandler
                Set_Default_Handler  USBD_WKUP_IRQHandler
                Set_Default_Handler  EXMC_IRQHandler

                .end