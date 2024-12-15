# Unit Test with Pytest


Unit testing involves testing individual components of software in __isolation to ensure they function correctly__. Automated frameworks facilitate this process, which __is integral to ensuring that new changes do not disrupt existing functionality__. Unit tests also serve as practical documentation and encourage better software design. This testing method boosts development speed and confidence by confirming component reliability before integration. Early bug detection through unit testing also helps minimize future repair costs and efforts.

# pytest

Pytest is one of the best tools that you can use to boost your testing productivity for Python codes.
## Install
- `pip install pytest`
- `pip install pytest-cov`
	- `pytest --cov`: this returns a coverage of test functions 
	- `coverage html`: log test results in html format


## Example

`pytest` is a libarary for testing.  You can run your unit test code by
```sh
pytest test_function.py
```

If you wanna create a directory with several testing files, then just create `__init__.py` and put it inside the test dir. 
- Then, just run `pytest test_dir` 


```python
from calc import square
import pytest

def square(n):
    return n*n

# This is a convention test_{func}
def test_negative():
    assert square(-2)==4
    assert square(-3)==9

def test_positive():
    assert square(2)==4
    assert square(3)==9

def test_zero():
    assert square(0)==0

def test_str():
    # Write down what I expect to get 
    # If it successfully raised the error that I expected
    # Then, it will pass the test
    with pytest.raises(TypeError):
        square("cat")

def main():
    x = int(input("What's x? "))
    print("x squared is", square(x))

if __name__=="__main__":
    main()
```
- If you want to intentially raise an error, then you can do it by `pytest.raises("SomeErrorType")`

Note that you can write a warning message like  
```python
assert x == <cond>, <MSG>
```


