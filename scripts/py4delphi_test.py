
from PythonModule1 import printme  
    
def print_data(handle):
    
    print('starting script...')  

    for i in range(10000):
        print(i)
        val1 = 2.5 + i
        val2 = 'this is the iteration number ' + str(i)
        printme(handle, i, val1, val2)

