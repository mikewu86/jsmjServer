#include <stdio.h>
#include <string.h>
#include <stdint.h>

typedef struct {
	uint32_t state[5];
	uint32_t count[2];
	uint8_t  buffer[64];
} SHA1_CTX;
 
#define SHA1_DIGEST_SIZE 20

static void	SHA1_Transform(uint32_t	state[5], const	uint8_t	buffer[64]);

#define	rol(value, bits) (((value) << (bits)) |	((value) >>	(32	- (bits))))

/* blk0() and blk()	perform	the	initial	expand.	*/
/* I got the idea of expanding during the round	function from SSLeay */
/* FIXME: can we do	this in	an endian-proof	way? */
#ifdef WORDS_BIGENDIAN
#define	blk0(i)	block.l[i]
#else
#define	blk0(i)	(block.l[i]	= (rol(block.l[i],24)&0xFF00FF00) \
	|(rol(block.l[i],8)&0x00FF00FF))
#endif
#define	blk(i) (block.l[i&15] =	rol(block.l[(i+13)&15]^block.l[(i+8)&15] \
	^block.l[(i+2)&15]^block.l[i&15],1))

/* (R0+R1),	R2,	R3,	R4 are the different operations	used in	SHA1 */
#define	R0(v,w,x,y,z,i)	z+=((w&(x^y))^y)+blk0(i)+0x5A827999+rol(v,5);w=rol(w,30);
#define	R1(v,w,x,y,z,i)	z+=((w&(x^y))^y)+blk(i)+0x5A827999+rol(v,5);w=rol(w,30);
#define	R2(v,w,x,y,z,i)	z+=(w^x^y)+blk(i)+0x6ED9EBA1+rol(v,5);w=rol(w,30);
#define	R3(v,w,x,y,z,i)	z+=(((w|x)&y)|(w&x))+blk(i)+0x8F1BBCDC+rol(v,5);w=rol(w,30);
#define	R4(v,w,x,y,z,i)	z+=(w^x^y)+blk(i)+0xCA62C1D6+rol(v,5);w=rol(w,30);


/* Hash	a single 512-bit block.	This is	the	core of	the	algorithm. */
static void	SHA1_Transform(uint32_t	state[5], const	uint8_t	buffer[64])
{
	uint32_t a,	b, c, d, e;
	typedef	union {
		uint8_t	c[64];
		uint32_t l[16];
	} CHAR64LONG16;
	CHAR64LONG16 block;

	memcpy(&block, buffer, 64);

	/* Copy	context->state[] to	working	vars */
	a =	state[0];
	b =	state[1];
	c =	state[2];
	d =	state[3];
	e =	state[4];

	/* 4 rounds	of 20 operations each. Loop	unrolled. */
	R0(a,b,c,d,e, 0); R0(e,a,b,c,d,	1);	R0(d,e,a,b,c, 2); R0(c,d,e,a,b,	3);
	R0(b,c,d,e,a, 4); R0(a,b,c,d,e,	5);	R0(e,a,b,c,d, 6); R0(d,e,a,b,c,	7);
	R0(c,d,e,a,b, 8); R0(b,c,d,e,a,	9);	R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
	R0(d,e,a,b,c,12); R0(c,d,e,a,b,13);	R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
	R1(e,a,b,c,d,16); R1(d,e,a,b,c,17);	R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
	R2(a,b,c,d,e,20); R2(e,a,b,c,d,21);	R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
	R2(b,c,d,e,a,24); R2(a,b,c,d,e,25);	R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
	R2(c,d,e,a,b,28); R2(b,c,d,e,a,29);	R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
	R2(d,e,a,b,c,32); R2(c,d,e,a,b,33);	R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
	R2(e,a,b,c,d,36); R2(d,e,a,b,c,37);	R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
	R3(a,b,c,d,e,40); R3(e,a,b,c,d,41);	R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
	R3(b,c,d,e,a,44); R3(a,b,c,d,e,45);	R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
	R3(c,d,e,a,b,48); R3(b,c,d,e,a,49);	R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
	R3(d,e,a,b,c,52); R3(c,d,e,a,b,53);	R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
	R3(e,a,b,c,d,56); R3(d,e,a,b,c,57);	R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
	R4(a,b,c,d,e,60); R4(e,a,b,c,d,61);	R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
	R4(b,c,d,e,a,64); R4(a,b,c,d,e,65);	R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
	R4(c,d,e,a,b,68); R4(b,c,d,e,a,69);	R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
	R4(d,e,a,b,c,72); R4(c,d,e,a,b,73);	R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
	R4(e,a,b,c,d,76); R4(d,e,a,b,c,77);	R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);

	/* Add the working vars	back into context.state[] */
	state[0] +=	a;
	state[1] +=	b;
	state[2] +=	c;
	state[3] +=	d;
	state[4] +=	e;

	/* Wipe	variables */
	a =	b =	c =	d =	e =	0;
}


/* SHA1Init	- Initialize new context */
static void sat_SHA1_Init(SHA1_CTX* context)
{
	/* SHA1	initialization constants */
	context->state[0] =	0x67452301;
	context->state[1] =	0xEFCDAB89;
	context->state[2] =	0x98BADCFE;
	context->state[3] =	0x10325476;
	context->state[4] =	0xC3D2E1F0;
	context->count[0] =	context->count[1] =	0;
}


/* Run your	data through this. */
static void sat_SHA1_Update(SHA1_CTX* context,	const uint8_t* data, const size_t len)
{
	size_t i, j;

#ifdef VERBOSE
	SHAPrintContext(context, "before");
#endif

	j =	(context->count[0] >> 3) & 63;
	if ((context->count[0] += len << 3)	< (len << 3)) context->count[1]++;
	context->count[1] += (len >> 29);
	if ((j + len) >	63)	{
		memcpy(&context->buffer[j],	data, (i = 64-j));
		SHA1_Transform(context->state, context->buffer);
		for	( ;	i +	63 < len; i	+= 64) {
			SHA1_Transform(context->state, data	+ i);
		}
		j =	0;
	}
	else i = 0;
	memcpy(&context->buffer[j],	&data[i], len -	i);

#ifdef VERBOSE
	SHAPrintContext(context, "after	");
#endif
}


/* Add padding and return the message digest. */
static void sat_SHA1_Final(SHA1_CTX* context, uint8_t digest[SHA1_DIGEST_SIZE])
{
	uint32_t i;
	uint8_t	 finalcount[8];

	for	(i = 0;	i <	8; i++)	{
		finalcount[i] =	(unsigned char)((context->count[(i >= 4	? 0	: 1)]
		 >>	((3-(i & 3)) * 8) )	& 255);	 /*	Endian independent */
	}
	sat_SHA1_Update(context, (uint8_t *)"\200",	1);
	while ((context->count[0] &	504) !=	448) {
		sat_SHA1_Update(context, (uint8_t *)"\0", 1);
	}
	sat_SHA1_Update(context, finalcount, 8);  /* Should	cause a	SHA1_Transform() */
	for	(i = 0;	i <	SHA1_DIGEST_SIZE; i++) {
		digest[i] =	(uint8_t)
		 ((context->state[i>>2]	>> ((3-(i &	3))	* 8) ) & 255);
	}

	/* Wipe	variables */
	i =	0;
	memset(context->buffer,	0, 64);
	memset(context->state, 0, 20);
	memset(context->count, 0, 8);
	memset(finalcount, 0, 8);	/* SWR */
}


#include "skynet_malloc.h"

#include "skynet_socket.h"
#include <lua.h>
#include <lauxlib.h>
#include <ctype.h>
#include <arpa/inet.h>
#include <assert.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


#define __DEBUG(str) //printf("%s\n", str);

#define QUEUESIZE 1024
#define HASHSIZE 4096
#define SMALLSTRING 2048

#define TYPE_DATA 1
#define TYPE_MORE 2
#define TYPE_ERROR 3
#define TYPE_OPEN 4
#define TYPE_CLOSE 5
#define SKYNET_CONTEXT 6
#define WS_CLOSE_NORMAL 1000
#define WS_CLOSE_PROTO_ERROR 1002
#define WS_CLOSE_GENERIC 1008
#define WS_STATE_HS 0
#define WS_STATE_F0H 1
#define WS_STATE_F0B 2
#define WS_STATE_F1H 3
#define WS_STATE_F1B 4

/* 
         
   HS-->F0H-->F0B-->F1H-->F1B
         ^     |           |
         |     |           |
         +-----+-----------+
 */

/*
  Each package is uint16 + data , uint16 (serialized in big-endian) is the number of bytes comprising the data .
*/

struct netpack {
        int id;
        uint64_t size;
        void * buffer;
};

struct ws_conn {
        struct netpack pack;
        struct ws_conn *next;
        uint8_t state;
        int read;
        int hread;
        void *http_header;
        char client[22];
        char clientreal[22];
        union {
                uint8_t frame_header[14];
                struct {
                        uint8_t fin;
                        uint8_t opcode;
                        uint32_t mask;
                        int len;
                };
        };
};

struct queue {
        int cap;
        int head;
        int tail;
        struct ws_conn * hash[HASHSIZE];
        struct netpack queue[QUEUESIZE];
};
static inline int
hash_fd(int fd) {
        int a = fd >> 24;
        int b = fd >> 12;
        int c = fd;
        return (int)(((uint32_t)(a + b + c)) % HASHSIZE);
}

static struct queue *
get_queue(lua_State *L) {
        struct queue *q = lua_touserdata(L,1);
        if (q == NULL) {
                q = lua_newuserdata(L, sizeof(struct queue));
                q->cap = QUEUESIZE;
                q->head = 0;
                q->tail = 0;
                int i;
                for (i=0;i<HASHSIZE;i++) {
                        q->hash[i] = NULL;
                }
                lua_replace(L, 1);
        }
        return q;
}

static struct ws_conn *
ws_search_conn(struct queue *q, int fd)
{
        if (q == NULL) {
                return NULL;
        }
        int h = hash_fd(fd);
        struct ws_conn *conn = q->hash[h];
        if (conn == NULL) {
                return NULL;
        }
        if (conn->pack.id == fd) {
                return conn;
        }
        struct ws_conn *last = conn;
        while (last->next) {
                conn = last->next;
                if (conn->pack.id == fd) {
                        return conn;
                }
                last = conn;
        }
        return NULL;
}

static void
ws_delete_conn(struct queue *q, int fd)
{
        if (q == NULL) {
                return;
        }
        int h = hash_fd(fd);
        struct ws_conn *conn = q->hash[h];
        if (conn == NULL) {
                return;
        }
        if (conn->pack.id == fd) {
                q->hash[h] =conn->next;
                if (conn->http_header) {
                  skynet_free(conn->http_header);
                }
                skynet_free(conn);
                return;
        }
        struct ws_conn *last = conn;
        while (last->next) {
                conn = last->next;
                if (conn->pack.id == fd) {
                  last->next = conn->next;
                  if (conn->http_header) {
                    skynet_free(conn->http_header);
                  }
                  skynet_free(conn);
                  return; 
                }
                last = conn;
        }
}

static struct ws_conn *
ws_create_conn(lua_State *L, int fd)
{
        struct queue *q = get_queue(L);
        int h = hash_fd(fd);
        struct ws_conn *conn = skynet_malloc(sizeof(struct ws_conn));
        memset(conn, 0, sizeof(*conn));
        conn->next = q->hash[h];
        conn->pack.id = fd;
        conn->pack.size = 0;
        conn->pack.buffer = NULL;
        q->hash[h] = conn;
        conn->hread = 0;
        conn->state = WS_STATE_HS;
        conn->read = 0;
        return conn;
}

static int
my_strstr(char *orig, int size, char *search)
{
        int i;
        int len = strlen(search);
        for (i = 0; i < size - len + 1; i++) {
                if (strncasecmp(orig + i, search, len) == 0) {
                        return i;
                }
        }
        return -1;
}
static int
first_character(char *orig, int size)
{
        int i;
        for (i = 0; i < size; i++) {
                if (isalnum(orig[i])) {
                        return i;
                }
        }
        return -1;
}

static int
first_nonspace(char *orig, int size)
{
        int i;
        for (i = 0; i < size; i++) {
                if (orig[i] != 32 && orig[i] != '\t') {
                        return i;
                }
        }
        return -1;
}

/* 
< 0 error
= 0 uncomplete
> 0 handshake size
 */
static uint64_t
ws_check_handshake_complete(char *buffer, uint64_t size)
{
        if (size < 3) {
                return 0;
        }

        if (strncmp(buffer, "GET", 3) != 0) {
                __DEBUG("GET failed");
                return -1;
        }

        if (size >= 4096) {
                __DEBUG("size > 4096");
                return -1;
        }
        int http_end = my_strstr(buffer, size, "\r\n\r\n");
        if (http_end < 0) {
                return 0;
        }
        
        int http_len = http_end + 4;

        if (my_strstr(buffer, http_len, "HTTP/1.1\r\n") < 0) {
                __DEBUG("no http/1.1");
                return -1;
        }
        
        int upgrade_idx = my_strstr(buffer, http_len, "upgrade:");
        if (upgrade_idx < 0) {
                __DEBUG("no upgrade");
                return -1;
        }
        int upgrade_value_idx = first_character(buffer + upgrade_idx + 7, http_len - upgrade_idx - 7);

        if (upgrade_value_idx < 0 || strncasecmp(buffer + upgrade_idx + 7 + upgrade_value_idx, "websocket", 9) != 0) {
                __DEBUG("upgrade not websocket");
                return -1;
        }

        int connection_idx = my_strstr(buffer, http_len, "connection:");
        if (connection_idx < 0) {
                __DEBUG("no connection");
                return -1;
        }
        int connection_value_idx = first_character(buffer + connection_idx + 10, http_len - connection_idx - 10);
        if (connection_value_idx < 0 || strncasecmp(buffer + connection_idx + 10 + connection_value_idx, "upgrade", 7) != 0) {
                __DEBUG("connection not upgrade");
                return -1;
        }

        int sec_ws_ver_idx = my_strstr(buffer, http_len, "sec-websocket-version:");
        if (sec_ws_ver_idx < 0) {
                __DEBUG("no sec-websocket-version");
                return -1;
        }
        int sec_ws_ver_value_idx = first_character(buffer + sec_ws_ver_idx + 21, http_len - sec_ws_ver_idx - 21);
        if (sec_ws_ver_value_idx < 0 || strncasecmp(buffer + sec_ws_ver_idx + 21 + sec_ws_ver_value_idx, "13", 2) != 0) {
                __DEBUG("sec-websocket-version not 13");
                return -1;
        }

        int sec_ws_key_idx = my_strstr(buffer, http_len, "sec-websocket-key:");
        if (sec_ws_key_idx < 0) {
                __DEBUG("not sec-websocket-key");
                return -1;
        }

        return http_len;
}

static uint64_t
ws_check_frameheader_complete(uint8_t *buffer, uint64_t size)
{
        if (size < 2) {
                return 0;
        }
        if ((buffer[1] & 128) == 0) {
                /* int i; */
                /* for (i = 0; i < size; i++) { */
                /*         printf("%x ", buffer[i]); */
                /* } */
                /* printf("\n"); */
                
                return -1;
        }
        int header_len;
        
        int pack_size = buffer[1] & 127;
        if (pack_size < 126) {
                header_len = 6;
        } else if (pack_size == 126) {
                header_len = 8;
        } else {
                header_len = 14;
        }

        if (size < header_len) {
                return 0;
        }

                /* int i; */
                /* for (i = 0; i < size; i++) { */
                /*         printf("%x ", buffer[i]); */
                /* } */
                /* printf(" len %d\n", header_len); */

        return header_len;
        
}

static void
ws_send_handshake(struct skynet_context *ctx, int fd, char *header, int size)
{
        
        int sec_ws_key_idx = my_strstr(header, size, "sec-websocket-key:");
        int sec_ws_key_value_idx = first_nonspace(header + sec_ws_key_idx + 18, size - sec_ws_key_idx - 18) + sec_ws_key_idx + 18;
        int sec_ws_key_value_end = my_strstr(header + sec_ws_key_value_idx, size - sec_ws_key_value_idx, "\r\n") + sec_ws_key_value_idx;
        int key_len = sec_ws_key_value_end - sec_ws_key_value_idx;
        int append_len = strlen("258EAFA5-E914-47DA-95CA-C5AB0DC85B11");
        uint8_t buffer[key_len + append_len];

        memcpy(buffer, header + sec_ws_key_value_idx, key_len);
        memcpy(buffer + key_len, "258EAFA5-E914-47DA-95CA-C5AB0DC85B11", append_len);

        SHA1_CTX shactx;
        int hash_len = SHA1_DIGEST_SIZE;
        uint8_t sha1hash[hash_len];
        sat_SHA1_Init(&shactx);
        sat_SHA1_Update(&shactx, buffer, key_len + append_len);
        sat_SHA1_Final(&shactx, sha1hash);
        
	static const char* encoding = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        int encode_sz = (hash_len + 2)/3*4;
        char tmp[encode_sz + 1];
	int i,j;
	j=0;
	for (i=0;i<(int)hash_len-2;i+=3) {
		uint32_t v = sha1hash[i] << 16 | sha1hash[i+1] << 8 | sha1hash[i+2];
		tmp[j] = encoding[v >> 18];
		tmp[j+1] = encoding[(v >> 12) & 0x3f];
		tmp[j+2] = encoding[(v >> 6) & 0x3f];
		tmp[j+3] = encoding[(v) & 0x3f];
		j+=4;
	}
	int padding = hash_len-i;
	uint32_t v;
	switch(padding) {
	case 1 :
		v = sha1hash[i];
		tmp[j] = encoding[v >> 2];
		tmp[j+1] = encoding[(v & 3) << 4];
		tmp[j+2] = '=';
		tmp[j+3] = '=';
		break;
	case 2 :
		v = sha1hash[i] << 8 | sha1hash[i+1];
		tmp[j] = encoding[v >> 10];
		tmp[j+1] = encoding[(v >> 4) & 0x3f];
		tmp[j+2] = encoding[(v & 0xf) << 2];
		tmp[j+3] = '=';
		break;
	}
        tmp[encode_sz] = '\0';

        char protocol[1024] = "";
        char *out = skynet_malloc(4096);
        
        int sec_ws_proto_idx = my_strstr(header, size, "sec-websocket-protocol:");
        if (sec_ws_proto_idx >= 0) {
                int sec_ws_proto_end = my_strstr(header + sec_ws_proto_idx, size - sec_ws_proto_idx, "\r\n") + sec_ws_proto_idx;
                int proto_len = sec_ws_proto_end - sec_ws_proto_idx;
                memcpy(protocol, header + sec_ws_proto_idx, proto_len);
                protocol[proto_len] = '\0';
                sprintf(out,
                        "HTTP/1.1 101 Switching Protocols\r\n"
                        "Upgrade: websocket\r\n"
                        "Connection: Upgrade\r\n"
                        "Sec-WebSocket-Accept: %s\r\n"
                        "%s\r\n\r\n", tmp, protocol);
        } else {
                sprintf(out,
                        "HTTP/1.1 101 Switching Protocols\r\n"
                        "Upgrade: websocket\r\n"
                        "Connection: Upgrade\r\n"
                        "Sec-WebSocket-Accept: %s\r\n"
                        "\r\n", tmp);
        }

        skynet_socket_send(ctx, fd, out, strlen(out)); 
}

static uint64_t
ws_read_size(uint8_t *header)
{
        int pack_size = header[1] & 127;
        if (pack_size < 126) {
                return pack_size;
        } else if (pack_size == 126) {
                return ntohs(*((uint16_t *) (header + 2)));
        } else {
                uint64_t hi = ntohl(*((uint32_t *) (header + 6)));
                uint64_t low = ntohl(*((uint32_t *) (header + 2)));
                return hi << 32 | low;
        }
}

static int
ws_read_opcode(uint8_t *header)
{
        return header[0] & 0xf;
}

static uint32_t
ws_read_mask(uint8_t *header)
{
        int pack_size = header[1] & 127;
        if (pack_size < 126) {
                return *((uint32_t *) (header + 2));
        } else if (pack_size == 126) {
                return *((uint32_t *) (header + 4));
        } else {
                return *((uint32_t *) (header + 10));
        }
}

static int
ws_read_fin(uint8_t *header)
{
        return header[0] >> 7;
}

static int
ws_send_frame(struct skynet_context *ctx, int fd, uint8_t opcode, uint8_t *buffer, int size)
{
        uint8_t *frame = skynet_malloc(size + 14);
        uint32_t hdr_len = 2;
        frame[0] = 0x80 | opcode;
        if (size < 126) {
                frame[1] = size;
        } else if (size <= 65536) {
                hdr_len += 2;
                frame[1] = 126;
                *((uint16_t *) (frame + 2)) = htons(size);
        }
        memcpy(frame + 2, buffer, size);
        return skynet_socket_send(ctx, fd, frame, size + hdr_len);
}
static int
ws_handle_control_frame(struct skynet_context *ctx, int fd, uint8_t opcode, uint8_t *buffer, int size)
{
        uint8_t rsp[1024];
        switch (opcode) {
        case 0x1:
        case 0x2:
                return 0;
        case 0x8:
                *((uint16_t *) rsp) = WS_CLOSE_GENERIC;
                ws_send_frame(ctx, fd, 0x8, rsp, 2);
                skynet_socket_close(ctx, fd);
                return 1;
        case 0x9:
        case 0xa:
        default:
                return 1;
        }
}

static void
ws_unmask_data(uint8_t *dst, uint8_t *src, int size, uint32_t mask)
{
        int i;
        uint8_t *m = (uint8_t *) &mask;
        for (i = 0; i < size; i++) {
                dst[i] = src[i] ^ m[i % 4];
        }
}


static void
clear_list(struct ws_conn * conn) {
        while (conn) {
                struct ws_conn * tmp = conn;
                conn = conn->next;
                if (tmp->http_header) {
                        skynet_free(tmp->http_header);
                }
                skynet_free((void *) tmp);
        }
}

static int
lclear(lua_State *L) {
        struct queue * q = lua_touserdata(L, 1);
        if (q == NULL) {
                return 0;
        }
        int i;
        for (i=0;i<HASHSIZE;i++) {
                clear_list(q->hash[i]);
                q->hash[i] = NULL;
        }
        if (q->head > q->tail) {
                q->tail += q->cap;
        }
        for (i=q->head;i<q->tail;i++) {
                struct netpack *np = &q->queue[i % q->cap];
                skynet_free(np->buffer);
        }
        q->head = q->tail = 0;

        return 0;
}


static void
expand_queue(lua_State *L, struct queue *q) {
        struct queue *nq = lua_newuserdata(L, sizeof(struct queue) + q->cap * sizeof(struct netpack));
        nq->cap = q->cap + QUEUESIZE;
        nq->head = 0;
        nq->tail = q->cap;
        memcpy(nq->hash, q->hash, sizeof(nq->hash));
        memset(q->hash, 0, sizeof(q->hash));
        int i;
        for (i=0;i<q->cap;i++) {
                int idx = (q->head + i) % q->cap;
                nq->queue[i] = q->queue[idx];
        }
        q->head = q->tail = 0;
        lua_replace(L,1);
}

static void
push_data(lua_State *L, int fd, void *buffer, int size, int clone, uint32_t mask) {
        if (clone) {
                void * tmp = skynet_malloc(size);
                ws_unmask_data(tmp, buffer, size, mask);                
                buffer = tmp;
        }
        struct queue *q = get_queue(L);
        struct netpack *np = &q->queue[q->tail];
        if (++q->tail >= q->cap)
                q->tail -= q->cap;
        np->id = fd;
        np->buffer = buffer;
        np->size = size;
        if (q->head == q->tail) {
                expand_queue(L, q);
        }
}

static int
filter_data_(lua_State *L, int fd, uint8_t * buffer, uint64_t size) {
        struct queue *q = lua_touserdata(L,1);
        struct ws_conn *conn = ws_search_conn(q, fd);
        struct skynet_context *ctx = lua_touserdata(L, lua_upvalueindex(SKYNET_CONTEXT));
        int more_flag = 0;

        if (!conn) {
                skynet_socket_close(ctx, fd);
                return 1;
        }
        if (conn->state == WS_STATE_HS) { 
                if (!conn->http_header) {
                        conn->http_header = skynet_malloc(4096);
                }
                uint64_t max_copy_len = size < 4096 - conn->read ? size : 4096 - conn->read;
                assert(max_copy_len + conn->read <= 4096);
                memcpy(conn->http_header + conn->read, buffer, max_copy_len);
                int hs_len = ws_check_handshake_complete(conn->http_header, conn->read + max_copy_len);
                assert(hs_len <= 4096);
                if (hs_len < 0) {
                        skynet_socket_close(ctx, fd);
                        ws_delete_conn(q, fd);
                        lua_pushvalue(L, lua_upvalueindex(TYPE_ERROR));
                        lua_pushinteger(L, fd);
                        lua_pushliteral(L, "handshake error");
                        return 4;
                } else if (hs_len == 0) {
                        conn->read += size;
                } else {
                        uint64_t consume = hs_len - conn->read;
                        //get user real ip from http_header
                        int x_forwarded_for_idx = my_strstr(conn->http_header, hs_len, "x-forwarded-for:");
                        //assert(x_forwarded_for_idx >= 0);
                        if (x_forwarded_for_idx < 0) {
                                __DEBUG("no x-forwarded-for");
                                memcpy(conn->clientreal, conn->client, strlen(conn->client));
                        }
                        else {
                                int x_forwarded_for_value_idx = first_character(conn->http_header + x_forwarded_for_idx + 15, hs_len - x_forwarded_for_idx - 15) + x_forwarded_for_idx + 15;
                                int x_forwarded_for_value_end = my_strstr(conn->http_header + x_forwarded_for_value_idx, hs_len - x_forwarded_for_value_idx, "\r\n") + x_forwarded_for_value_idx;
                                int key_len = x_forwarded_for_value_end - x_forwarded_for_value_idx;
                                if (key_len > 21) {
                                        __DEBUG("no clientreal too long");
                                        memcpy(conn->clientreal, conn->client, strlen(conn->client));
                                }
                                else {
                                        //assert(key_len <= 21);
                                        //printf("x_forwarded_for_value_idx:%d  key_len:%d x_forwarded_for_idx:%d x_forwarded_for_value_end:%d", x_forwarded_for_value_idx, key_len, x_forwarded_for_idx, x_forwarded_for_value_end);
                                        memcpy(conn->clientreal, conn->http_header + x_forwarded_for_value_idx, key_len);
                                }
                        }
                        
                        
                        printf("http_header:  %s\n", conn->http_header);
                        ws_send_handshake(ctx, fd, conn->http_header, hs_len);
                        assert(size == consume);
                        conn->state = WS_STATE_F0H;
                        conn->read = 0;
                        conn->hread = 0;
                        skynet_free(conn->http_header);
                        conn->http_header = NULL;
                        lua_pushvalue(L, lua_upvalueindex(TYPE_OPEN));
                        lua_pushinteger(L, fd);
                        //lua_pushliteral(L, "handshake");
                        lua_pushlstring(L, conn->clientreal, strlen(conn->clientreal));
                        return 4;                        
                }
                return 1;
        }

        for (;;) {
                if (conn->state == WS_STATE_F0H || conn->state == WS_STATE_F1H) {
                        conn->read = 0;
                        int max_copy_len = size < 14 - conn->hread ? size : 14 - conn->hread;
                        memcpy(conn->frame_header + conn->hread, buffer, max_copy_len);
                        int ws_hdr_len = ws_check_frameheader_complete(conn->frame_header, max_copy_len + conn->hread);
                        
                        if (ws_hdr_len < 0) {
                                uint16_t code = WS_CLOSE_PROTO_ERROR;
                                ws_send_frame(ctx, fd, 0x8, (uint8_t *)&code, 2);
                                ws_delete_conn(q, fd);
                                skynet_socket_close(ctx, fd);
                                lua_pushvalue(L, lua_upvalueindex(TYPE_ERROR));
                                lua_pushinteger(L, fd);
                                lua_pushliteral(L, "frameheader error");
                        } else if (ws_hdr_len == 0) {
                                conn->hread += max_copy_len;
                                return 1;
                        } else {
                                int consume = ws_hdr_len - conn->hread;
                                conn->hread = 0;
                                uint8_t opcode = ws_read_opcode(conn->frame_header);
                                uint32_t mask = ws_read_mask(conn->frame_header);
                                int len = ws_read_size(conn->frame_header);
                                uint8_t fin = ws_read_fin(conn->frame_header);
                                conn->opcode = opcode;
                                conn->mask = mask;
                                conn->len = len;
                                conn->fin = fin;
                                conn->state = conn->fin ? WS_STATE_F1B : WS_STATE_F0B;
                                conn->pack.size += conn->len;
                                if (conn->pack.buffer) {
                                        conn->pack.buffer = skynet_realloc(conn->pack.buffer, conn->pack.size);
                                } else {
                                        conn->pack.buffer = skynet_malloc(conn->pack.size);
                                }
                                buffer += consume;
                                size -= consume;
                        }
                        continue;
                }
                if (conn->state == WS_STATE_F0B) {
                        conn->hread = 0;
                        int need = conn->len - conn->read;
                        if (size < need) {
                                ws_unmask_data(conn->pack.buffer + conn->read, buffer, size, conn->mask);
                                conn->read += size;
                                return 1;
                        } else {
                                ws_unmask_data(conn->pack.buffer + conn->read, buffer, need, conn->mask);
                                conn->read += need;
                                buffer += need;
                                size -= need;
                                conn->state = WS_STATE_F0H;
                        }
                        continue;
                }
                if (conn->state == WS_STATE_F1B) {
                        conn->hread = 0;
                        int need = conn->len - conn->read;
                        if (size < need) {
                                memcpy(conn->pack.buffer + conn->read, buffer, size);
                                conn->read += size;
                                return 1;
                        } else {
                                memcpy(conn->pack.buffer + conn->read, buffer, need);
                                ws_unmask_data(conn->pack.buffer, conn->pack.buffer, conn->pack.size, conn->mask);
                                conn->state = WS_STATE_F0H;
                                conn->read = 0;
                                if (ws_handle_control_frame(ctx, fd, conn->opcode, conn->pack.buffer, conn->pack.size)) {
                                        skynet_free(conn->pack.buffer);
                                        conn->pack.size = 0;
                                        conn->pack.buffer = NULL;
                                } else {
                                        if (!more_flag && size == need) {
                                                lua_pushvalue(L, lua_upvalueindex(TYPE_DATA));
                                                lua_pushinteger(L, fd);
                                                lua_pushlightuserdata(L, conn->pack.buffer);
                                                lua_pushinteger(L, conn->pack.size);
                                                conn->pack.buffer = NULL;
                                                conn->pack.size = 0;
                                                return 5;
                                        }
                                        push_data(L, fd, conn->pack.buffer, conn->pack.size, 0, conn->mask);
                                        conn->pack.buffer = NULL;
                                        conn->pack.size = 0;
                                        
                                        if (more_flag && size == need) {
                                                lua_pushvalue(L, lua_upvalueindex(TYPE_MORE));
                                                return 2;
                                        }
                                }
                                buffer += need;
                                size -= need;
                                more_flag = 1;
                        }
                        continue;
                }
        }
        return 1;
}

static inline int
filter_data(lua_State *L, int fd, uint8_t * buffer, int size) {
        int ret = filter_data_(L, fd, buffer, size);
        // buffer is the data of socket message, it malloc at socket_server.c : function forward_message .
        // it should be free before return,
        skynet_free(buffer);
        return ret;
}

/*
  userdata queue
  lightuserdata msg
  integer size
  return
  userdata queue
  integer type
  integer fd
  string msg | lightuserdata/integer
*/
static int
lfilter(lua_State *L) {
        struct ws_conn *conn;
        struct skynet_socket_message *message = lua_touserdata(L,2);
        int size = luaL_checkinteger(L,3);
        char * buffer = message->buffer;
        if (buffer == NULL) {
                buffer = (char *)(message+1);
                size -= sizeof(*message);
        } else {
                size = -1;
        }

        lua_settop(L, 1);
        
        switch(message->type) {
        case SKYNET_SOCKET_TYPE_DATA:
                assert(size == -1);	// never padding string
                return filter_data(L, message->id, (uint8_t *)buffer, message->ud);
        case SKYNET_SOCKET_TYPE_CONNECT:
                return 1;
        case SKYNET_SOCKET_TYPE_CLOSE:
                ws_delete_conn(get_queue(L), message->id);
                lua_pushvalue(L, lua_upvalueindex(TYPE_CLOSE));
                lua_pushinteger(L, message->id);
                return 3;
        case SKYNET_SOCKET_TYPE_ACCEPT:
                conn = ws_create_conn(L, message->ud);
                assert(size <= 21);
                memcpy(conn->client, buffer, size);
                skynet_socket_start(lua_touserdata(L, lua_upvalueindex(SKYNET_CONTEXT)), message->ud);
                return 1;
        case SKYNET_SOCKET_TYPE_ERROR:
                ws_delete_conn(get_queue(L), message->id);
                lua_pushvalue(L, lua_upvalueindex(TYPE_ERROR));
                lua_pushinteger(L, message->id);
                lua_pushlstring(L, buffer, size);
                return 4;
        default:
                // never get here
                return 1;
        }
}

/*
  userdata queue
  return
  integer fd
  lightuserdata msg
  integer size
*/
static int
lpop(lua_State *L) {
        struct queue * q = lua_touserdata(L, 1);
        if (q == NULL || q->head == q->tail)
                return 0;
        struct netpack *np = &q->queue[q->head];
        if (++q->head >= q->cap) {
                q->head = 0;
        }

/* //        printf("%lu\n", np->size); */
        /* uint8_t c = ((uint8_t *)np->buffer)[np->size]; */
        /* ((uint8_t *)np->buffer)[np->size] = '\0'; */
        /* printf("%s %u\n", (char *)np->buffer, (uint32_t)np->size); */
        /* ((uint8_t *)np->buffer)[np->size] = c; */
        

        lua_pushinteger(L, np->id);
        lua_pushlightuserdata(L, np->buffer);
        lua_pushinteger(L, np->size);

        return 3;
}

/*
  string msg | lightuserdata/integer

  lightuserdata/integer
*/

static const char *
tolstring(lua_State *L, size_t *sz, int index) {
        const char * ptr;
        if (lua_isuserdata(L,index)) {
                ptr = (const char *)lua_touserdata(L,index);
                *sz = (size_t)luaL_checkinteger(L, index+1);
        } else {
                ptr = luaL_checklstring(L, index, sz);
        }
        return ptr;
}

static inline void
write_size(uint8_t * buffer, int len) {
        buffer[0] = (len >> 8) & 0xff;
        buffer[1] = len & 0xff;
}

#define FRAME_SET_FIN(BYTE) (((BYTE) & 0x01) << 7)
#define FRAME_SET_OPCODE(BYTE) ((BYTE) & 0x0F)
#define FRAME_SET_MASK(BYTE) (((BYTE) & 0x01) << 7)
#define FRAME_SET_LENGTH(X64, IDX) (unsigned char)(((X64) >> ((IDX)*8)) & 0xFF)


static int
lpack(lua_State *L) {
	size_t len;
	const char * ptr = tolstring(L, &len, 1);

	int pos = 0;
    char frame_header[16];

    frame_header[pos++] = FRAME_SET_FIN(1) | FRAME_SET_OPCODE(2);
    if (len < 126)
    {
        frame_header[pos++] = FRAME_SET_MASK(0) | FRAME_SET_LENGTH(len, 0);
    }
    else
    {
        if (len < 65536)
        {
            frame_header[pos++] = FRAME_SET_MASK(0) | 126;
        }
        else
        {
            frame_header[pos++] = FRAME_SET_MASK(0) | 127;
            frame_header[pos++] = FRAME_SET_LENGTH(len, 7);
            frame_header[pos++] = FRAME_SET_LENGTH(len, 6);
            frame_header[pos++] = FRAME_SET_LENGTH(len, 5);
            frame_header[pos++] = FRAME_SET_LENGTH(len, 4);
            frame_header[pos++] = FRAME_SET_LENGTH(len, 3);
            frame_header[pos++] = FRAME_SET_LENGTH(len, 2);
        }
        frame_header[pos++] = FRAME_SET_LENGTH(len, 1);
        frame_header[pos++] = FRAME_SET_LENGTH(len, 0);
    }
		
	uint8_t * buffer = skynet_malloc(len + pos);
	memcpy(buffer, frame_header, pos);
	memcpy(buffer+pos, ptr, len);

	lua_pushlightuserdata(L, buffer);
	lua_pushinteger(L, len + pos);

	return 2;
}

/*
static int
lpack(lua_State *L) {
        size_t len;
        const char * ptr = tolstring(L, &len, 1);
        if (len > 0x10000) {
                return luaL_error(L, "Invalid size (too long) of data : %d", (int)len);
        }

        uint8_t * buffer = skynet_malloc(len + 2);
        write_size(buffer, len);
        memcpy(buffer+2, ptr, len);

        lua_pushlightuserdata(L, buffer);
        lua_pushinteger(L, len + 2);

        return 2;
}
*/

static int
lpack_string(lua_State *L) {
        uint8_t tmp[SMALLSTRING+2];
        size_t len;
        uint8_t *buffer;
        const char * ptr = tolstring(L, &len, 1);
        if (len > 0x10000) {
                return luaL_error(L, "Invalid size (too long) of data : %d", (int)len);
        }

        if (len <= SMALLSTRING) {
                buffer = tmp;
        } else {
                buffer = lua_newuserdata(L, len + 2);
        }

        write_size(buffer, len);
        memcpy(buffer+2, ptr, len);
        lua_pushlstring(L, (const char *)buffer, len+2);

        return 1;
}

static int
lpack_padding(lua_State *L) {
        uint8_t tmp[SMALLSTRING+2];
        size_t content_sz;
        uint8_t *buffer;
        const char * ptr = tolstring(L, &content_sz, 2);
        size_t cookie_sz = 0;
        const char * cookie = luaL_checklstring(L,1,&cookie_sz);
        size_t len = cookie_sz + content_sz;

        if (len > 0x10000) {
                return luaL_error(L, "Invalid size (too long) of data : %d", (int)len);
        }

        if (len <= SMALLSTRING) {
                buffer = tmp;
        } else {
                buffer = lua_newuserdata(L, len + 2);
        }

        write_size(buffer, len);
        memcpy(buffer+2, ptr, content_sz);
        memcpy(buffer+2+content_sz, cookie, cookie_sz);
        lua_pushlstring(L, (const char *)buffer, len+2);

        return 1;
}

static int
ltostring(lua_State *L) {
        void * ptr = lua_touserdata(L, 1);
        int size = luaL_checkinteger(L, 2);
        if (ptr == NULL) {
                lua_pushliteral(L, "");
        } else {
                if (lua_isnumber(L, 3)) {
                        int offset = lua_tointeger(L, 3);
                        if (offset < 0) {
                                return luaL_error(L, "Invalid offset %d", offset);
                        }
                        if (offset > size) {
                                offset = size;
                        }
                        lua_pushlstring(L, (const char *)ptr + offset, size-offset);
                } else {
                        lua_pushlstring(L, (const char *)ptr, size);
                        skynet_free(ptr);
                }
        }
        return 1;
}

static void *
get_buffer(lua_State *L, int index, int *sz) {
	void *buffer;
	if (lua_isuserdata(L,index)) {
		buffer = lua_touserdata(L,index);
		*sz = luaL_checkinteger(L,index+1);
	} else {
		size_t len = 0;
		const char * str =  luaL_checklstring(L, index, &len);
		buffer = skynet_malloc(len);
		memcpy(buffer, str, len);
		*sz = (int)len;
	}
	return buffer;
}

static int
lsend(lua_State *L) {
        struct skynet_context *ctx = lua_touserdata(L, lua_upvalueindex(SKYNET_CONTEXT));
        int id = luaL_checkinteger(L, 1);
        int sz = 0;
        void *buffer = get_buffer(L, 2, &sz);
        int err = ws_send_frame(ctx, id, 0x2, buffer, sz);
        lua_pushboolean(L, !err);
        return 1;
}

int
luaopen_websocket(lua_State *L) {
        luaL_checkversion(L);
        luaL_Reg l[] = {
                { "pop", lpop },
                { "pack", lpack },
                { "pack_string", lpack_string },
                { "pack_padding", lpack_padding },
                { "clear", lclear },
                { "tostring", ltostring },
                { NULL, NULL },
        };
        luaL_newlib(L,l);

        luaL_Reg l2[] = {
                { "send", lsend },
                { "filter", lfilter},
                {NULL, NULL},
        };

        // the order is same with macros : TYPE_* (defined top)
        lua_pushliteral(L, "data");
        lua_pushliteral(L, "more");
        lua_pushliteral(L, "error");
        lua_pushliteral(L, "open");
        lua_pushliteral(L, "close");
        lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
        struct skynet_context *ctx = lua_touserdata(L, -1);
        if (ctx == NULL) {
                return luaL_error(L, "Init skynet context first");
        }
        luaL_setfuncs(L, l2, 6);

        return 1;
}