#include <kern/e1000.h>
#include <kern/pmap.h>
#include <inc/string.h>


// LAB 6: Your driver code here
uint32_t mac[2] = {0x12005452, 0x5634};
volatile uint32_t *e1000;
struct tx_descriptor tx_d[TXRING_LEN] __attribute__((aligned(PGSIZE)))
    = {{0, 0, 0, 0, 0, 0, 0}};
struct packet pbuf[TXRING_LEN] __attribute__((aligned(PGSIZE)))
    = {{{0}}};
struct rx_descriptor rx_d[RXRING_LEN] __attribute__((aligned(PGSIZE)))
    = {{0, 0, 0, 0, 0, 0}};
struct packet prbuf[RXRING_LEN] __attribute__((aligned(PGSIZE)))
    = {{{0}}};

static void 
init_descbuf(){
    int i;
    
    for (i = 0; i < TXRING_LEN; ++i){
        tx_d[i].addr = PADDR(&pbuf[i]);
        tx_d[i].status = TXD_STAT_DD;
        tx_d[i].cmd = TXD_CMD_RS | TXD_CMD_EOP;
    }

    for (i = 0; i < RXRING_LEN; ++i){
        rx_d[i].addr = PADDR(&prbuf[i]);
        rx_d[i].status = 0;
    }
}

int e1000_transmit(void *addr, size_t len){
    uint32_t tail = e1000[TDT / 4];
    struct tx_descriptor *next = &tx_d[tail];

    if (!(next->status & TXD_STAT_DD))
        return -1;

    if (len > TBUFFSIZE)
        len = TBUFFSIZE;

    memmove(&pbuf[tail], addr, len);
    next->length = (uint16_t)len;
    next->status &= !TXD_STAT_DD;
    e1000[TDT / 4] = (tail + 1) % TXRING_LEN;

    return 0;
}

int e1000_receive(void *addr, size_t buflen){
    uint32_t tail = (e1000[RDT / 4] + 1) % RXRING_LEN;
    struct rx_descriptor *next = &rx_d[tail];

    if (!(next->status & RXD_STAT_DD))
        return -1;

    if (next->length < buflen)
        buflen = next->length;

    memmove(addr, &prbuf[tail], buflen);
    next->status &= !RXD_STAT_DD;
    e1000[RDT / 4] = tail;

    return buflen;
}

int pci_e1000_attach(struct pci_func *pcif){
    pci_func_enable(pcif);
    init_descbuf();

    e1000 = mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
    // cprintf("e1000: bar0  %x size0 %x\n", pcif->reg_base[0], pcif->reg_size[0]);
    // cprintf("e1000: status %x\n", e1000[0x00008/4]);

    e1000[TDBAL / 4] = PADDR(tx_d);
    e1000[TDBAH / 4] = 0;
    e1000[TDLEN / 4] = TXRING_LEN * sizeof(struct tx_descriptor);
    e1000[TDH / 4] = 0;
    e1000[TDT / 4] = 0;
    e1000[TCTL / 4] = TCTL_EN | TCTL_PSP | (TCTL_CT & (0x10 << 4)) | (TCTL_COLD & (0x40 << 12));
    e1000[TIPG / 4] = 10 | (8 << 10) | (12 << 20);

    e1000[RA / 4] = mac[0];
    e1000[RA / 4 + 1] = mac[1];
    e1000[RA / 4 + 1] |= RAV;

    cprintf("e1000: mac address %x:%x\n", mac[1], mac[0]);

    memset((void*)&e1000[MTA / 4], 0, RXRING_LEN * 4);
    e1000[ICS / 4] = 0;
    e1000[IMS / 4] = 0;
    e1000[RDBAL / 4] = PADDR(rx_d);
    e1000[RDBAH / 4] = 0;
    e1000[RDH / 4] = 0;
    e1000[RDLEN / 4] = RXRING_LEN * sizeof(struct rx_descriptor);
    e1000[RDT / 4] = RXRING_LEN - 1;
    e1000[RCTL / 4] = RCTL_EN | RCTL_LBM_NO | RCTL_SECRC | RCTL_BSIZE | RCTL_BAM;

    return 0;
}