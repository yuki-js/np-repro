# ノート

## 何があったの

最初 WSL で NumPy を使ったソフトウェアを実行しようとしていたんだけど、いつからか(2023/4/12 あたりで判明した)どうしてか知らないけれど wsl.exe が閉じてしまうバグに遭遇してしまったので調査を開始した
それで、レースコンディション絡みで Linux カーネルのバグを踏んでしまったようだということがわかった。

## 現状

いろいろな条件でテストして、カーネルのコアダンプをとっている。デカいので載せない。

- よく動いたパターン
  - 1 P-Core, 16 E-Core
  - PL1=PL2=30W
  - 4 P-core, 0 E-core
- 動かないパターン
  - 16 P-Core, 0 E-Core
  - 16 P-Core, 16 E-Core

### 変更した条件

- CPU
  - PL1, PL2(min: 30W, max: 無制限つまり MTP である 253W)
  - P-Core の個数: 1(HT 無効), 8(HT 無効), 16(HT 有効)
  - E-Core の個数: 0(Gaming mode), 16
  - P-Core の周波数: 2GHz - 5.8GHz
  - E-Core の周波数: 2GHz - 4.3GHz

## ChatGPT とデバッグをしてみる

### Python script caused kernel crash

User

I am analyzing kernel crash dump with crash command
bt command said

```
PID: 10250    TASK: ffff915b53351940  CPU: 8    COMMAND: "python3"
 #0 [ffffb6490f0a78e0] machine_kexec at ffffffff8808c5b0
 #1 [ffffb6490f0a7940] __crash_kexec at ffffffff8819ac02
 #2 [ffffb6490f0a7a10] crash_kexec at ffffffff8819c45c
 #3 [ffffb6490f0a7a20] oops_end at ffffffff88041e0a
 #4 [ffffb6490f0a7a48] page_fault_oops at ffffffff8809e422
 #5 [ffffb6490f0a7aa8] do_user_addr_fault at ffffffff8809ec01
 #6 [ffffb6490f0a7b00] exc_page_fault at ffffffff88da7a27
 #7 [ffffb6490f0a7b30] asm_exc_page_fault at ffffffff88e00b67
    [exception RIP: __bitmap_andnot+66]
    RIP: ffffffff88640942  RSP: ffffb6490f0a7be8  RFLAGS: 00010083
    RAX: ffffffffffffffff  RBX: ffff915b4006c1c0  RCX: 00000000ffffffe0
    RDX: 0000000000000028  RSI: 0000000000000000  RDI: ffff915b4006c1c0
    RBP: ffffb6490f0a7c38   R8: 0000000000000028   R9: ffff915b4006c1c0
    R10: 0000000000000020  R11: 0000000000000000  R12: 0000000000000020
    R13: 000000000001ff38  R14: 0000000000030303  R15: 0000000000000028
    ORIG_RAX: ffffffffffffffff  CS: 0010  SS: 0018
 #8 [ffffb6490f0a7be8] __x2apic_send_IPI_mask at ffffffff8808a70d
 #9 [ffffb6490f0a7c40] x2apic_send_IPI_mask at ffffffff8808a7c3
#10 [ffffb6490f0a7c50] native_send_call_func_ipi at ffffffff880824c4
#11 [ffffb6490f0a7c78] smp_call_function_many_cond at ffffffff8818f51a
#12 [ffffb6490f0a7cf0] on_each_cpu_cond_mask at ffffffff8818f61d
#13 [ffffb6490f0a7d00] native_flush_tlb_multi at ffffffff880a26e9
#14 [ffffb6490f0a7d20] flush_tlb_mm_range at ffffffff880a289e
#15 [ffffb6490f0a7d60] tlb_finish_mmu at ffffffff8830907d
#16 [ffffb6490f0a7d88] unmap_region at ffffffff88303906
#17 [ffffb6490f0a7e50] __do_munmap at ffffffff88305d5d
#18 [ffffb6490f0a7eb0] __vm_munmap at ffffffff883060c9
#19 [ffffb6490f0a7f08] __x64_sys_munmap at ffffffff8830620d
#20 [ffffb6490f0a7f28] do_syscall_64 at ffffffff88da3af9
#21 [ffffb6490f0a7f50] entry_SYSCALL_64_after_hwframe at ffffffff88e00099
    RIP: 00007ffff7feba97  RSP: 00007fffffffaca8  RFLAGS: 00000202
    RAX: ffffffffffffffda  RBX: 00007fffffffacd0  RCX: 00007ffff7feba97
    RDX: 0000000000000000  RSI: 000000000000459e  RDI: 00007ffff559f000
    RBP: 0000000000000000   R8: 0000000000000000   R9: 00007fffb5be16c0
    R10: 0000000000000008  R11: 0000000000000202  R12: 00007fffffffed18
    R13: 0000000000000002  R14: 0000000000654420  R15: 00007ffff7ffda28
    ORIG_RAX: 000000000000000b  CS: 0033  SS: 002b
```

Based on this, please explain what the heck happened at that time of kernel panic.

ChatGPT

Based on the information provided in the backtrace (bt) output, it seems that the kernel panic occurred while running a Python3 process. The backtrace shows the sequence of function calls that led to the panic. Here's a high-level explanation of the events:

    A page fault occurred, and the kernel attempted to handle it (functions #4 - #7).
    During this process, the kernel encountered an exception in the __bitmap_andnot function (function RIP: __bitmap_andnot+66).
    This led to a series of inter-processor communication attempts (functions #8 - #13) to synchronize the changes across all CPU cores.
    The kernel then attempted to flush the translation lookaside buffer (TLB) (functions #14 - #15).
    Following that, the kernel tried to unmap memory regions (functions #16 - #19).
    Finally, the kernel executed a system call (munmap) to unmap memory regions (functions #20 - #21).

The actual cause of the kernel panic is not entirely clear from the backtrace alone. However, it appears to be related to memory management, possibly due to an issue with handling a page fault or unmapping memory regions. Further analysis, such as examining the kernel logs, dmesg output, or any relevant application logs, might provide more insights into the cause of the panic. Additionally, checking for known issues or bug reports for the specific kernel version or related software can help identify potential causes and solutions.

User
hmm, is it okay that system call is executed at last? isn't it at first? or my misunderstanding?

ChatGPT

I apologize for any confusion. You're right to question the order of events I previously mentioned. The backtrace should be read in reverse order, as it shows the sequence of function calls that led to the kernel panic, starting from the most recent function call.

So, the correct order of events is:

    The Python3 process made a system call (munmap) to unmap memory regions (functions #20 - #21).
    The kernel started to handle the munmap request and tried to unmap memory regions (functions #16 - #19).
    Then, the kernel attempted to flush the translation lookaside buffer (TLB) (functions #14 - #15).
    A series of inter-processor communication attempts (functions #8 - #13) were made to synchronize the changes across all CPU cores.
    During this process, the kernel encountered an exception in the __bitmap_andnot function (function RIP: __bitmap_andnot+66).
    The kernel tried to handle a page fault (functions #4 - #7), which ultimately led to the panic.

So, the system call was indeed executed first, and the events that followed led to the kernel panic.


## カーネルパニック集
### WSLでLinuxカーネルをビルドしたとき
```
[   24.832716] divide error: 0000 [#1] SMP NOPTI
[   24.833319] CPU: 24 PID: 1961 Comm: make Not tainted 5.15.90.1-microsoft-standard-WSL2 #1
[   24.833797] RIP: 0010:__check_heap_object+0x37/0xd0
[   24.834146] Code: 89 f8 48 2b 15 3a 09 46 01 48 c1 fa 06 48 c1 e2 0c 48 03 15 3b 09 46 01 48 39 d7 0f 82 80 00 00 00 44 8b 4e 18 48 29 d0 48 99 <49> f7 f9 8b 86 b0 00 00 00 39 d0 77 1a 8b be b4 00 00 00 41 89 d2
[   24.835190] RSP: 0018:ffffc90005677e28 EFLAGS: 00010206
[   24.835528] RAX: 000000000000007b RBX: 000000000000000d RCX: 0000000000000000
[   24.835926] RDX: 0000000000000000 RSI: ffff888745e6df71 RDI: ffff888753d5b07b
[   24.836490] RBP: ffff888753d5b088 R08: 000000000000000d R09: 0000000000000000
[   24.836940] R10: 0000000000000008 R11: 0000000000000000 R12: ffff888753d5b07b
[   24.837645] R13: 0000000000000000 R14: 0000000000000000 R15: 000000000000000d
[   24.838208] FS:  00007f7315e58740(0000) GS:ffff8887e0800000(0000) knlGS:0000000000000000
[   24.838798] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   24.839639] CR2: 00007f7315e57ff8 CR3: 000000061d33a006 CR4: 0000000000370ea0
[   24.840026] Call Trace:
[   24.840247]  <TASK>
[   24.840618]  __check_object_size+0x146/0x160
[   24.840979]  copy_strings.isra.0+0x177/0x360
[   24.841359]  do_execveat_common.isra.0+0x15e/0x230
[   24.841724]  __x64_sys_execve+0x33/0x40
[   24.841921]  do_syscall_64+0x38/0xc0
[   24.842140]  entry_SYSCALL_64_after_hwframe+0x61/0xcb
[   24.842426] RIP: 0033:0x7f7315f460fb
[   24.842670] Code: f8 01 0f 8e bd fe ff ff 5b 48 8d 3d df 59 13 00 5d 41 5c e9 97 62 fa ff 0f 1f 80 00 00 00 00 f3 0f 1e fa b8 3b 00 00 00 0f 05 <48> 3d 01 f0 ff ff 73 01 c3 48 8b 0d 05 dd 12 00 f7 d8 64 89 01 48
[   24.843934] RSP: 002b:00007f7315e57e68 EFLAGS: 00000202 ORIG_RAX: 000000000000003b
[   24.844559] RAX: ffffffffffffffda RBX: 00007ffd20073500 RCX: 00007f7315f460fb
[   24.844944] RDX: 0000563958bfdd50 RSI: 0000563958bff540 RDI: 0000563958bffa70
[   24.845436] RBP: 00007f7315e57ff0 R08: 00007ffd20073928 R09: 0000000000000000
[   24.845897] R10: 0000000000000008 R11: 0000000000000202 R12: 00007f7315e57f20
[   24.846323] R13: 0000000000000001 R14: 00007ffd200737d0 R15: 0000000000000041
[   24.846791]  </TASK>
[   24.846994] Modules linked in:
[   24.847242] ---[ end trace f1035ebaeb6e8f30 ]---
[   24.847532] RIP: 0010:__check_heap_object+0x37/0xd0
[   24.847821] Code: 89 f8 48 2b 15 3a 09 46 01 48 c1 fa 06 48 c1 e2 0c 48 03 15 3b 09 46 01 48 39 d7 0f 82 80 00 00 00 44 8b 4e 18 48 29 d0 48 99 <49> f7 f9 8b 86 b0 00 00 00 39 d0 77 1a 8b be b4 00 00 00 41 89 d2
[   24.848810] RSP: 0018:ffffc90005677e28 EFLAGS: 00010206
[   24.849111] RAX: 000000000000007b RBX: 000000000000000d RCX: 0000000000000000
[   24.849564] RDX: 0000000000000000 RSI: ffff888745e6df71 RDI: ffff888753d5b07b
[   24.849981] RBP: ffff888753d5b088 R08: 000000000000000d R09: 0000000000000000
[   24.850413] R10: 0000000000000008 R11: 0000000000000000 R12: ffff888753d5b07b
[   24.850901] R13: 0000000000000000 R14: 0000000000000000 R15: 000000000000000d
[   24.851346] FS:  00007f7315e58740(0000) GS:ffff8887e0800000(0000) knlGS:0000000000000000
[   24.851759] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[   24.852103] CR2: 00007f7315e57ff8 CR3: 000000061d33a006 CR4: 0000000000370ea0
[   24.852467] Kernel panic - not syncing: Fatal exception
[   29.845456] hv_vmbus: Waiting for VMBus UNLOAD to complete
```