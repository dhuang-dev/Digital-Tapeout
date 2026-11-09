val |= (1U << pos) //to 1
val &= ˜(1U << pos) //to 0
val ˆ= (1U << pos) //switch
// pos in this case is position of bit
// n & (n-1) clears lowest bit (ex: 12, 0b11100, 12-1 = 11 = 0b11011, 0b11100 & 0b11011 = 0b11000, clears lowest 1 bit)
// a ptr stores memory address
int* ptr = arr //stores memory at arr[0]
*ptr //gets memory at arr
ptr + 1 //moves ptr forward by 1 element size

//Count Totals 1s
int countBits(uint32_t n) {
    int count = 0;
    while (n > 0) {
        n &= (n - 1); // Magic trick: clears the lowest 1-bit!
        count++;
    }
    return count;
}

//Reverse Bits
uint32_t reverseBits(uint32_t n) {
    uint32_t result = 0;
    for (int i = 0; i < 32; i++) {
        result <<= 1;       // 1. Make room in result
        result |= (n & 1);  // 2. Copy the lowest bit of n into result
        n >>= 1;            // 3. Drop the lowest bit of n
    }
    return result;
}

//Array count
int arr[4] = {10, 20, 30, 40};
int* ptr = arr; // 'ptr' points to the first element (arr[0] = 10)

// Pointer Arithmetic Rules:
*ptr;        // Value at address -> 10
*(ptr + 1);  // Value at next element -> 20 (same as arr[1])
ptr++;       // Moves the pointer to point to arr[1]

struct Node {
    uint32_t data; // Data payload (e.g., hardware packet or register value)
    Node* next;    // Pointer to the next node in memory (or nullptr if end)
};

//Clear all bits in a certain range
#include <cstdint>

uint32_t clearBitRange(uint32_t val, int start, int end) {
    // WRITE YOUR CODE HERE
    while (end >= start){
        val &= ~(1U << end);
        end = end - 1;
    }
}
//OR 
uint32_t clearBitRange(uint32_t val, int start, int end) {
    for (int i = start; i <= end; i++) {
        val &= ~(1U << i); // Clear each bit in the range one by one
    }
    return val;
}

//Linked List Node: count how many nodes = target
struct Node {
    uint32_t data;
    Node* next;
};

int countOccurrences(Node* head, uint32_t target) {
    int count = 0;
    Node* curr = head;
    while (curr != nullptr){
        if (curr->data == target){
            count = count + 1;
        }
        curr = curr->next;
    }
    return count;
}

//Question 1 Task: In hardware registers, updating a specific bitfield requires clearing the old value first, then ORing in the new value. 
//Write a function uint32_t updateField(uint32_t reg, uint8_t newValue, int startBit, int fieldWidth) that:
//Clears fieldWidth bits starting at index startBit.
//Places the lowest fieldWidth bits of newValue into that cleared location.
//Returns the updated register value.
//Example: reg = 0xFFaFFFFFF, newValue = 0x5 (0b0101), startBit = 4, fieldWidth = 4.
//Clearing bits 4–7 makes reg = 0xFFFFFF0F.
//Placing 0x5 at bit 4 makes reg = 0xFFFFFF5F.

#include <cstdint>

uint32_t updateField(uint32_t reg, uint8_t newValue, int startBit, int fieldWidth) {
    // YOUR CODE HERE
    for(int i = 0; i <= fieldWidth; i++){
        reg &= ~(1U << startBit);
        startBit = startBit + 1;
    }
    reg |= ((uint32_t)newValue << start);
    return reg;
}

//Question 2: Swapping Bits
//Task: Write a function uint32_t swapBits(uint32_t val, int pos1, int pos2) that swaps the bits at 
//positions pos1 and pos2 in val.
//Hint: If the bits at pos1 and pos2 are already identical (both 0 or both 1), swapping them changes nothing! 
//If they are different, toggle both bits using XOR (^).

#include <cstdint>

uint32_t swapBits(uint32_t val, int pos1, int pos2) {
    // YOUR CODE HERE
    bool bit1 = (val >> pos1) & 1;
    bool bit2 = (val >> pos2) & 1;
    if (bit1 != bit2){
        val ˆ= (1U << pos1);
        val ˆ= (1U << pos2);
    }
    return val;
}

//Question 3: Finding the Maximum Value in a Linked List
//Task: Write a function uint32_t findMaxNode(Node* head) that traverses a 
//singly linked list and returns the largest data value found. 
//If the list is empty (head == nullptr), return 0.
struct Node {
    uint32_t data;
    Node* next;
};

uint32_t findMaxNode(Node* head) {
    if(head == nullptr){
            return 0;
        }
    Node* curr = head;
    uint32_t maxVal = head->data;
    while (curr != nullptr){
        if(curr->data > maxVal){
            maxVal = curr->data;
        }
        curr = curr->next;
    }
    return maxVal
}

//Question 4: Question 4: Searching for a Register Value in an Array
//Task: Write a function int searchRegister(const uint32_t* arr, int size, uint32_t targetReg)
//that searches an array of register values for targetReg using a standard indexed for loop. 
//Return the index if found, or -1 if not present.
#include <cstdint>

int searchRegister(const uint32_t* arr, int size, uint32_t targetReg) {
    // YOUR CODE HERE
    const uint32_t* ptr = arr
    for (int i = 0; i < size; i++){
        if (*ptr == targetReg){
            return i;
        }   
        ptr++;
    }
    return -1;
}
//or without pointer
#include <cstdint>

int searchRegister(const uint32_t* arr, int size, uint32_t targetReg) {
    for (int i = 0; i < size; i++) {
        // If we find the target, return its index immediately!
        if (arr[i] == targetReg) {
            return i;
        }
    }

    // If the loop finishes, targetReg was never in the array
    return -1;
}

//Given a 32-bit register reg, extract a field that starts at bit LSB and is width bits long. 
//Return the extracted field as a right-aligned uint32_t value.

uint32_t extractField(uint32_t reg, int lsb, int width) {
    uint32_t mask = (1U << width) - 1;
    return (reg >> lsb) & mask;
}

//In digital communication, parity checks ensure data integrity. 
//Write a function that returns true if a 32-bit integer has even parity (an even number of set 1 bits), 
//and false if it has odd parity.

bool hasEvenParity(uint32_t val){
    int count = 0;
    while(val!=0){
        val &= (val-1);
        count++;
    }
    if (count%2 == 0){
        return true;
    }
    else{
        return false;
    }
}

//Hardware FIFOs use circular buffers. 
//Given a fixed-size array buffer of size CAPACITY, a head index (where the next read happens), and numItems to read, 
//write a function that sums up the next numItems starting from head, wrapping around the buffer if necessary.

uint32_t sumCircularBuffer(const uint32_t* buffer, int capacity, int head, int numItems) {
    uint32_t sum = 0;
    
    for (int i = 0; i < numItems; i++) {
        // Calculate the current index with circular wrap-around
        int currIndex = (head + i) % capacity;
        
        // Add buffer[currIndex] to sum
    }
    
    return sum;
}

//You are given the head of a singly linked list representing a sequence of control flags. 
//Traverse the list and invert (toggle 0 → 1, 1 → 0) the data field of every node that sits at an odd index (1-based position: 1st, 3rd, 5th, etc.). 
//Return the head pointer.


struct Node {
    uint32_t data; // Guaranteed to be either 0 or 1
    Node* next;
};

Node* toggleOddNodes(Node* head){
    int pos = 1;
    Node* curr = head;
    while (curr != nullptr){
        if (pos%2 == 1){
            curr->data ˆ= 1;
        }
        curr=curr->next;
        pos++;
    }
    return head;
}

//Problem 5: Base memory addresses in hardware must be aligned to a specific power-of-two byte boundary 
//(e.g., 4-byte, 16-byte, 64-byte).

//Write a function that returns true if address is aligned to alignment, and false otherwise.
//Constraint: Do this using bitwise operations (no modulo % or division / operators).
//Hint: If alignment = 16 (0b10000), an address is aligned if its lowest 4 bits are all zero (address & (alignment - 1) == 0).

#include <cstdint>
#include <cstddef>

bool isAligned(uintptr_t address, size_t alignment) {
    If(address & (alignment - 1) == 0){
        return true;
    }
}

//In low-level hardware drivers, hardware registers are accessed at specific memory addresses. 
//A common pattern is writing to a status/control register using bit masks.
//Write a function that updates a 32-bit hardware register's value by clearing a specific bitfield 
//(from lsb with a given width) and inserting a new value into that field.

uint32_t writeRegisterField(uint32_t regVal, int lsb, int width, uint32_t value){
    uint32_t valueshift = (value << lsb);
    uint32_t mask = ~((1U << width) -1) << lsb;
    regVal &= ~mask;
    regVal |= valueshift;
    return regVal;
    
}

//In hardware interfaces (like AXI or FIFO interfaces), data transfer occurs only when both 
//valid and ready signals are HIGH (1) on the same cycle.
//Given an array of 32-bit register transactions, where bit 0 represents VALID and bit 1 represents READY:
//Write a function that counts how many valid handshakes occurred in the sequence.

int countHandshakes(const uint32_t* transactions, int size){

    int count = 0;
        for (i=0;i<size;i++){
            uint32_t valid = (transactions [i] >> 0) & 1;
            uint32_t ready = (transactions [i] >> 1) & 1;
            if (valid == 1 & ready == 1){
                count++;
            }
        }
        return count;
}

//METHOD 2

int countHandshakes(const uint32_t* transactions, int size){
    int count = 0;
    for (i=0;i<size;i++){
        if (transactions [i] & 0b11 = 0b11){
            count++;
        }
    }
    return count;

}

// Problem 1: Detect a Hardware Flag Sequence (Match Pattern)
//In embedded software, you often process linked lists of incoming data packets to see if a specific sequence of flags 
//(e.g., 0xA followed immediately by 0xB) was received.
//Task: Write a function bool hasSequence(Node* head, uint32_t first, uint32_t second) 
//that returns true if two adjacent nodes contain first followed immediately by second.
//Example: 1 -> 5 -> 10 -> 12 with first = 5, second = 10 → returns true.
struct Node {
    uint32_t data;
    Node* next;
};

bool hasSequence(Node* head, uint32_t first, uint32_t second) {
    // YOUR CODE HERE
    Node* curr = head;
    while(curr != nullptr && curr->next != nullptr){
        Node* follow = curr->next;
        if(curr->data == first && follow == second){
            return true;
        }
        curr = curr->next;
    }
}



//In hardware queue management, noise packets under a signal threshold must be purged from memory before processing.
//Task: Given the head of a linked list and a threshold value, 
//remove all nodes whose data is strictly less than threshold. Return the updated head.
//Hint: Don't forget that the first node (head) itself might be less than threshold, so head can change!

Node* filterLowValues(Node* head, uint32_t threshold) {
    // YOUR CODE HERE
    while (head != nullptr && head->data < threshold){
        head=head->next;
    }
    Node* curr = head;
    while (curr != nullptr){
        if(curr->next->data < threshold){
            curr->next=curr->next->next;
        }
        else{
            curr=curr->next;
        }
    }
    return head;
}