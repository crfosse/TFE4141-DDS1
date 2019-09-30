#RSA - high level implementation

#RSA with Blakley's!
e_test = 0x10001
d_test = 0x2cd7623cd3aeb1ce577fc02f1593af0d3c336e60cf6cbd3e95eb1f277ddb43f1
n_test = 0x6e32c0e025e4f192804eddda592fd99db3ddb9510ef8a2e7ecd0f7e622973171
k_e_test = 17
k_d_test = 256
#k_m = 256
k_m=256
M_test = 0x4d697474206e61766e206572204361726c205269636861726420537465656e20
#M_test = 0x65425C53D3E85EB744604D6BCE056BE0995DF5C1FCD315974BCD3CB99853EF48
#M_test = 9

def binarymethod(M, e, n, k_e):
    # Function for RSA implementation using binary method
    # Calculates the ciphertext C = M^e mod n
    if e >> (k_e - 1) & 1: # If MSB of e is 1:
        C = M
    else:
        C = 1
    for i in range(k_e - 2, -1, -1): # Move through e bitwise from right to left
        C = (C * C) % n
        if (e >> i) & 1:        # If the current bit is 1
            C = blakley(C,M,n)  # Calculate C = C * M mod n using Blakley's
    return C

def blakley(a,b,n):
    # Function for calculating R = a * b mod n using Blakley's
    R = 0
    for j in range(0,k_m): # Move through all bits of a
        R = 2*R + (a >> (k_m-1-j) & 1) * b
        R = R % n

        if R >= n:  # Ensure the result is less than n
            R = R - n
        if R >= n:
            R = R - n
    return R

C_test = binarymethod(M_test,e_test,n_test, k_e_test)
print("Original: ", hex(M_test))
print("Encrypted: ",C_test)
print("Decrypted: ", hex(binarymethod(C_test,d_test,n_test, k_d_test)))

#print(blakley(4,5,7))

#Sliding window for bitwise operation
