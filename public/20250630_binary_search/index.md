# A Lesson from a Naive Binary Search


## A Lesson from a Naive Binary Search

I've been grinding hard every day, solving coding problems to get better at algorithms. Recently, I came across something interesting—a naive implementation of binary search can actually cause a bug. It's a small detail, but it matters.

```python
def binary_search(nums, target):
    left, right = 0, len(nums) - 1
    while left <= right:
        mid = (left + right) // 2
        if nums[mid] == target:
            return mid
        elif nums[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1
```
It works fine in Python—but I recently learned that the way I calculate `mid` can cause problems in some cases.

The issue is with this line:
```python
mid = (left + right) // 2
```

If `left` and `right` are very large, their sum might be too big in some languages, causing an **overflow**.

A safer way to write it is:
```python
mid = left + (right - left) // 2
```

**This version avoids adding two potentially large numbers.**

Even something as simple as binary search deserves careful thought. It reminded me that writing correct code isn't just about making it work—it's about making it right. 

